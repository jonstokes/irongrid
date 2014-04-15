module CDN
  class Image < CoreModel
    include Retryable

    attr_reader :source, :page, :file, :file_name, :s3, :http

    def initialize(opts)
      raise "Image source cannot be nil or empty!" unless opts[:source].present?
      @source = opts[:source]
      @http = opts[:http]
    end

    def destroy!
      retryable_with_aws { s3_objects[cdn_name].delete }
    end

    def exists?
      retryable_with_aws do
        s3_objects[cdn_name].exists? &&
          !s3_objects[cdn_name].content_length.zero?
      end
    end

    def cdn_url
      "#{cdn_image_prefix}#{cdn_name}"
    end

    def cdn_name
      @cdn_name ||= begin
        base = Digest::MD5.hexdigest(@source)
        extension = @source.split(".").last
        "#{base}.#{extension}"
      end
    end

    def delete_file!
      File.delete(file_name)
    end

    def download
      write_to_file if download_image
    end

    def resize
      return unless file_name

      # Zero length file issue could be related to speed at which I'm reading after
      # writing
      sleep 0.1

      begin
        ImageVoodoo.with_image(file_name) do |img|
          if img.width > 200
            img.thumbnail(200) { |thumb| thumb.save(thumb_file_name) }
          end
        end
      rescue Exception
        # Sometimes the above call to thumb.save is unsuccessful, for whatever reason
        # Probably because the library is old, wonky, and not maintained
        # rescue java exceptions for invalid image files
        # Could use java.lang.Throwable?
      end

      if File.exists?(thumb_file_name)
        if File.size(thumb_file_name).zero?
          File.delete(thumb_file_name)
        else
          File.delete(file_name)
          @file_name = thumb_file_name
        end
      end
    end

    def write_to_s3
      retryable_with_success do
        s3_objects[cdn_name].write(
          :file => file_name,
          :acl => :public_read,
          :reduced_redundancy => true
        )
      end
    ensure
      delete_file!
      # Ensure the HTTP pool is emptied after each write.
      AWS.config.http_handler.pool.empty!
    end

    def self.create(opts)
      image = Image.new(opts)
      if image.download
        image.resize
        image.write_to_s3
      end
      image
    end

    def self.exists?(image_source)
      Image.new(source: image_source).exists?
    end

    private

    def aws_connect!
      @s3 = AWS::S3.new(AWS_CREDENTIALS)
    end

    def index_bucket_name
      CDN.index_bucket_name
    end

    def s3_objects
      aws_connect! unless s3
      s3.buckets[index_bucket_name].objects
    end

    def download_image
      raise "Connection required!" unless @http.is_a?(PageUtils::HTTP)
      begin
        tries ||= 5
        @page = @http.fetch_page(source)
        sleep 0.5
      end until page.try(:body) || page.try(:not_found?) || (tries -= 1).zero?
      return unless page
      @page = nil if (page.not_found? || !page.body.present? || !page.image?)
      @page
    end

    def write_to_file
      # Sometimes the OS writes these as zero length files. Not entirely sure why yet.
      return @file_name = temp_file_name if File.open(temp_file_name, "wb") { |f| f.syswrite(page.body) } > 0
      File.delete(temp_file_name)
      @file_name = nil
    end

    def temp_file_name
      "tmp/#{cdn_name}"
    end

    def thumb_file_name
      "tmp/thumb-#{cdn_name}"
    end

    def cdn_image_prefix
      Rails.env.production? ? IMAGE_PREFIX : "https://s3.amazonaws.com/#{CDN.index_bucket_name}/"
    end
  end
end
