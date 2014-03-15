module CDN
  CDN_BASE_URL = Rails.env.test? ? "http://assets.scoperrific.com/" : "http://d27bctd90ej7xn.cloudfront.net/"
  DEFAULT_IMAGE_URL = "http://assets.scoperrific.com/no-image-200x140.png"

  class S3 < CoreModel
    include PageUtils
    include Retryable

    attr_reader :s3

    @use_test_image = false

    def initialize
      aws_connect!
    end

    def aws_connect!
      @s3 = AWS::S3.new(AWS_CREDENTIALS)
    end

    def delete_image_for_listing(listing)
      cdn_name = listing.image.sub(cdn_image_prefix,"")
      retryable_with_aws { s3.buckets[index_bucket_name].objects[cdn_name].delete }
    ensure
      # Ensure the HTTP pool is emptied after each write.
      AWS.config.http_handler.pool.empty!
    end

    def upload_image(image_url)
      return DEFAULT_IMAGE_URL unless image_url
      cdn_name = get_cdn_name(image_url)
      return get_cdn_image_url(cdn_name) if has_asset?(cdn_name)
      source_image_url = CDN::S3.use_test_image? ? TEST_IMAGE : image_url
      upload_image_to_s3(source_image_url, cdn_name)
    end

    def update_image_for_listing(image, listing)
      cdn_url = upload_image(image)
      delete_image_for_listing(listing) if (listing.image != cdn_url) && !listing.image_is_shared?
      cdn_url
    end

    def has_image?(image_url)
      cdn_name = get_cdn_name(image_url)
      has_asset?(cdn_name)
    end

    def count
      retryable_with_aws { s3.buckets[index_bucket_name].objects.count }
    end

    def clear!
      retryable_with_aws { s3.buckets[index_bucket_name].objects.each { |item| item.delete } }
    end

    def self.use_test_image?
      @use_test_image
    end

    def self.use_test_image!
      @use_test_image = true
    end

    def self.stop_using_test_image!
      @use_test_image = false
    end

    #
    # Private
    #
    def url_for_image(image)
      cdn_name = get_cdn_name(image)
      get_cdn_image_url(cdn_name)
    end

    def has_asset?(cdn_name)
      retryable_with_aws { s3.buckets[index_bucket_name].objects[cdn_name].exists? }
    ensure
      # Ensure the HTTP pool is emptied after each write.
      AWS.config.http_handler.pool.empty!
    end

    def index_bucket_name
      @index_bucket_name ||= "scoperrific-index" + ENV_BUCKET_POSTFIX
    end

    def get_cdn_name(image_name)
      base = Digest::MD5.hexdigest(image_name)
      extension = image_name.split(".").last
      "#{base}.#{extension}"
    end

    def cdn_image_prefix
      Rails.env.production? ? IMAGE_PREFIX : "https://s3.amazonaws.com/#{index_bucket_name}/"
    end

    def upload_image_to_s3(source_image_url, cdn_name)
      return DEFAULT_IMAGE_URL unless image_file = retryable_with_aws { open_link(source_image_url, false) }
      if (image_file.length == 0) || (image_file.is_a?(StringIO) && !!image_file.read[/html/])
        image_file.close
        return DEFAULT_IMAGE_URL
      end

      image_file.rewind
      image_file = resize(image_file, cdn_name) unless image_file.is_a?(StringIO)

      success = false
      success = retryable_with_success do
        s3.buckets[index_bucket_name].objects[cdn_name].write(:file => image_file, :acl => :public_read, :reduced_redundancy => true)
      end
      image_file.close
      File.delete(image_file.path) unless image_file.is_a?(StringIO)
      return success ? get_cdn_image_url(cdn_name) : DEFAULT_IMAGE_URL
    ensure
      # Ensure the HTTP pool is emptied after each write.
      AWS.config.http_handler.pool.empty!
    end

    def resize(file, cdn_name)
      tempfile_name = "tmp/#{cdn_name}"
      begin
        ImageVoodoo.with_image(file.path) do |img|
          if img.width > 200
            img.thumbnail(200) { |thumb| thumb.save(tempfile_name) }
          end
        end
      rescue Exception
        # rescue java exceptions for invalid image files
        # Could use java.lang.Throwable?
      end

      # Sometimes the above call to thumb.save is unsuccessful, for whatever reason
      if File.exists?(tempfile_name)
        file.close
        File.delete(file.path)
        File.open(tempfile_name)
      else
        file
      end
    end

    def image_width(url)
      return unless file = retryable_with_aws { open_link(url, false) }
      width = ImageVoodoo.with_image(file.path).width
      file.close
      File.delete(file.path)
      return width
    end

    def get_cdn_image_url(cdn_name)
      "#{cdn_image_prefix}#{cdn_name}"
    end
  end

  def self.delete_image_for_listing(listing)
    CDN::S3.new.delete_image_for_listing(listing)
  end

  def self.upload_image(image_url)
    CDN::S3.new.upload_image(image_url)
  end

  def self.update_image_for_listing(image, listing)
    CDN::S3.new.update_image_for_listing(image, listing)
  end

  def self.use_test_image!
    CDN::S3.use_test_image!
  end

  def self.stop_using_test_image
    CDN::S3.stop_using_test_image!
  end

  def self.with_test_image
    use_test_image!
    yield
    stop_using_test_image!
  end

  def self.has_image?(image_url)
    CDN::S3.new.has_image?(image_url)
  end

  def self.count
    CDN::S3.new.count
  end

  def self.clear!
    CDN::S3.new.clear!
  end

  def self.image_width(image)
    CDN::S3.new.image_width(image)
  end

  def self.url_for_image(image)
    CDN::S3.new.url_for_image(image)
  end
end
