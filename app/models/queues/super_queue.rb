require 'aws-sdk'
require 'base64'
require 'digest/md5'

class SuperQueue
  include Retryable

  BUFFER_SIZE = 10

  def self.mock!
    @@page_queue = Queue.new
    @@parsed_page_queue = Queue.new
    @@delete_listings_queue = Queue.new
    @@deactivate_listings_queue = Queue.new
  end

  def self.mocking?
    !!@@page_queue || @@parsed_page_queue
  end

  def self.stop_mocking!
    @@page_queue = @@parsed_page_queue = nil
  end

  class S3Pointer < Hash
    def initialize(key)
      super
      self.merge!(:s3_key => key)
    end

    def s3_key
      self[:s3_key]
    end

    def s3_key=(value)
      self[:s3_key] = value
    end
  end

  def initialize(opts)
    if SuperQueue.mocking?
      if opts[:name] == 'irongrid-parsed-page-queue'
        @q = @@parsed_page_queue
      elsif opts[:name] == 'irongrid-deactivate-listings-queue'
        @q = @@deactivate_listings_queue
      elsif opts[:name] == 'irongrid-delete-listings-queue'
        @q = @@delete_listings_queue
      else
        @q = @@page_queue
      end
      return
    end

    check_opts(opts)
    @queue_name = generate_queue_name(opts)
    @bucket_name = opts[:bucket_name] || queue_name unless opts[:disable_s3]
    @write_count = 0
    @read_count = 0
    @delete_count = 0
    initialize_aws(opts)

    @in_buffer = []
    @out_buffer = []
    @deletion_buffer = []

    fill_out_buffer_from_sqs_queue
  end

  def push(p)
    check_for_errors
    return @q.push(p) if SuperQueue.mocking?

    @in_buffer.push p
    clear_in_buffer if @in_buffer.size >= BUFFER_SIZE
  end

  def pop
    check_for_errors
    begin
      return @q.pop(true) if SuperQueue.mocking?
    rescue
      return nil
    end
    return if @out_buffer.compact.empty? && !(fill_out_buffer_from_sqs_queue || fill_out_buffer_from_in_buffer)
    m = @out_buffer.compact.shift
    @deletion_buffer << m
    collect_garbage! if @deletion_buffer.size >= BUFFER_SIZE
    m[:payload]
  end

  def length
    check_for_errors
    return @q.length if SuperQueue.mocking?
    return sqs_length + @in_buffer.size + @out_buffer.size
  end

  def empty?
    return @q.empty? if SuperQueue.mocking?
    len = 0
    2.times { len += self.length; sleep(0.01) }
    len == 0
  end

  def clear
    return @q.clear if SuperQueue.mocking?
    @in_buffer = []
    while @out_buffer.any? do
      @deletion_buffer << @out_buffer.shift
    end
    collect_garbage!

    begin
      sqs_handles = []
      @sqs_queue.receive_messages(:limit => 10).compact.each do |message|
        sqs_handles << message
      end
      @sqs_queue.batch_delete(sqs_handles) if sqs_handles.any?
    end until sqs_handles.empty?
    @bucket.objects.each { |o| o.delete } if use_s3? && !@bucket.empty?
  end

  def shutdown
    return true if SuperQueue.mocking?
    clear_in_buffer
    collect_garbage!
    @done = true
  end

  def destroy
    return true if SuperQueue.mocking?
    delete_aws_resources
    @done = true
  end

  def sqs_requests
    check_for_errors
    return 0 if SuperQueue.mocking?
    @write_count + @read_count + @delete_count
  end

  alias enq push
  alias << push

  alias deq pop
  alias shift pop

  alias size length

  def url
    q_url
  end

  def use_s3?
    !!@bucket_name
  end

  def name
    queue_name
  end

  private

  #
  # Amazon AWS methods
  #
  def initialize_aws(opts)
    retryable { aws_connect! }
    create_sqs_queue(opts)
    open_s3_bucket if use_s3?
  end

  def aws_connect!
    @sqs = AWS::SQS.new(AWS_CREDENTIALS)
    @s3 = AWS::S3.new(AWS_CREDENTIALS) if use_s3?
  end

  def create_sqs_queue(opts)
    tries = 5
    begin
      @sqs_queue = find_queue_by_name || new_sqs_queue(opts)
      check_for_queue_creation_success
    rescue Exception => e
      aws_connect!
      sleep 0.5
      (tries -= 1).zero? ? retry : raise(e)
    end
  end

  def open_s3_bucket
    @bucket = retryable(:tries => 3) do
      @s3.buckets[@bucket_name].exists? ? @s3.buckets[@bucket_name] : @s3.buckets.create(@bucket_name)
    end
  end

  def find_queue_by_name
    tries = 5
    begin
      @sqs.queues.named(queue_name)
    rescue AWS::SQS::Errors::NonExistentQueue
      return nil
    rescue Exception => e
      sleep 0.5
      (tries -= 1).zero? ? retry : raise(e)
    end
  end

  def new_sqs_queue(opts)
    @read_count += 1
    if opts[:visibility_timeout]
      retryable { @sqs.queues.create(queue_name, { :visibility_timeout => opts[:visibility_timeout] }) }
    else
      retryable { @sqs.queues.create(queue_name, { :visibility_timeout => 1800 }) }
    end
  end

  def check_for_queue_creation_success
    retries = 0
    while q_url.nil? && (retries < 5)
      retries += 1
      sleep 1
    end
    raise "Couldn't create queue #{queue_name}, or delete existing queue by this name." if q_url.nil?
  end

  def send_messages_to_queue(batches)
    batches.each do |b|
      @write_count += 1
      retryable(:tries => 5) do
        @sqs_queue.batch_send(b)
      end if b.any?
    end
  end

  def get_messages_from_queue(number_of_messages_to_receive)
    messages = []
    number_of_batches = number_of_messages_to_receive / 10
    number_of_batches += 1 if number_of_messages_to_receive % 10
    number_of_batches.times do
      retryable(:retries => 5) { messages += @sqs_queue.receive_messages(:limit => 10).compact }
      @read_count += 1
    end
    messages.compact
  end

  def send_payload_to_s3(encoded_message)
    key = "#{queue_name}/#{Digest::MD5.hexdigest(encoded_message)}"
    key_exists = false
    retryable(:tries => 5) { key_exists = @bucket.objects[key].exists? }
    return S3Pointer.new(key) if key_exists
    retryable(:tries => 5) { @bucket.objects[key].write(encoded_message, :reduced_redundancy => true) }
    S3Pointer.new(key)
  end

  def fetch_payload_from_s3(pointer)
    payload = nil
    retries = 0
    begin
      payload = decode(@bucket.objects[pointer.s3_key].read)
    rescue AWS::S3::Errors::NoSuchKey
      return nil
    rescue
      retries +=1
      retry if retries < 5
    end
    payload
  end

  def should_send_to_s3?(encoded_message)
    return unless use_s3?
    encoded_message.bytesize > 64000
  end

  def sqs_length
    n = 0
    n = retryable(:retries => 5) { @sqs_queue.visible_messages }
    @read_count += 1
    return n.is_a?(Integer) ? n : 0
  end

  def delete_aws_resources
    @delete_count += 1
    @sqs_queue.delete
    if use_s3?
      begin
        @bucket.clear!
        sleep 1
      end until @bucket.empty?
      @bucket.delete
    end
  end

  def collect_garbage!
    retryable(:tries => 4) do
      while !@deletion_buffer.empty?
        sqs_handles = @deletion_buffer[0..9].map { |m| m[:sqs_handle].is_a?(AWS::SQS::ReceivedMessage) ? m[:sqs_handle] : nil }.compact
        s3_keys = @deletion_buffer[0..9].map { |m| m[:s3_key] }.compact if use_s3?
        10.times { @deletion_buffer.shift }
        @sqs_queue.batch_delete(sqs_handles) if sqs_handles.any?
        s3_keys.each { |key| @bucket.objects[key].delete } if use_s3?
        @delete_count += 1
      end
    end
  end

  #
  # Buffer-related methods
  #
  def fill_out_buffer_from_sqs_queue
    return false if sqs_length == 0
    nil_count = 0
    while (@out_buffer.size < BUFFER_SIZE) && (nil_count < 5)
      messages = get_messages_from_queue(BUFFER_SIZE - @out_buffer.size)
      if messages.any?
        messages.each do |message|
          obj = decode(message.body)
          unless obj.is_a?(SuperQueue::S3Pointer)
            @out_buffer.push(
              :payload    => obj,
              :sqs_handle => message)
          else
            if p = fetch_payload_from_s3(obj)
              @out_buffer.push(
                :payload    => p,
                :sqs_handle => message,
                :s3_key     => obj.s3_key)
            else
              @deletion_buffer.push(:sqs_handle => message, :s3_key => obj.s3_key)
            end
          end
        end
        nil_count = 0
        sleep 0.01
      else
        nil_count += 1
      end
    end
    !@out_buffer.empty?
  end

  def fill_out_buffer_from_in_buffer
    return false if @in_buffer.empty?
    while (@out_buffer.size <= BUFFER_SIZE) && !@in_buffer.empty?
      @out_buffer.push(:payload => @in_buffer.shift)
    end
    !@out_buffer.empty?
  end

  def clear_in_buffer
    batches = []
    message_stash = []
    while !@in_buffer.empty? do
      batch = message_stash
      message_stash = []
      message_count = batch.size
      batch_too_big = false
      while !@in_buffer.empty? && !batch_too_big && (message_count < 10) do
        encoded_message = encode(@in_buffer.shift)
        message = should_send_to_s3?(encoded_message) ? encode(send_payload_to_s3(encoded_message)) : encoded_message
        if (batch_bytesize(batch) + message.bytesize) < 64000
          batch << message
          batch_too_big == false
          message_count += 1
        else
          message_stash << message
          batch_too_big = true
        end
      end
      batches << batch
    end
    send_messages_to_queue(batches)
  end

  #
  # Misc helper methods
  #
  def check_opts(opts)
    raise "Options can't be nil!" if opts.nil?
    raise "Minimun :buffer_size is 5." if opts[:buffer_size] && (opts[:buffer_size] < 5)
    raise "Visbility timeout must be an integer (in seconds)!" if opts[:visibility_timeout] && !opts[:visibility_timeout].is_a?(Integer)
  end

  def check_for_errors
    raise @gc_error if @gc_error
    raise @sqs_error if @sqs_error
    raise "Queue is no longer available!" if @done == true
  end

  def encode(p)
    Base64.urlsafe_encode64(Marshal.dump(p))
  end

  def decode(ser_obj)
    Marshal.load(Base64.urlsafe_decode64(ser_obj))
  end

  def generate_queue_name(opts)
    q_name = opts[:name] || random_name
    return opts[:namespace] ? "queue-#{opts[:namespace]}-#{q_name}" : "queue-#{q_name}"
  end

  def batch_bytesize(batch)
    sum = 0
    batch.each do |string|
      sum += string.bytesize
    end
    sum
  end

  #
  # Virtul attributes and convenience methods
  #
  def q_url
    return @q_url if @q_url
    @q_url = @sqs_queue.url
    @q_url
  end

  def random_name
    o =  [('a'..'z'),('1'..'9')].map{|i| i.to_a}.flatten
    random_element = (0...25).map{ o[rand(o.length)] }.join
    "temp-name-#{random_element}"
  end

  def queue_name
    @queue_name
  end
end
