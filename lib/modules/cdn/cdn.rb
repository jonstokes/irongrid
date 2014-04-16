module CDN
  include Retryable

  CDN_BASE_URL = Rails.env.test? ? "http://assets.scoperrific.com/" : "http://d27bctd90ej7xn.cloudfront.net/"
  DEFAULT_IMAGE_URL = "http://assets.scoperrific.com/no-image-200x140.png"

  def self.has_image?(image_url)
    Image.new(source: image_url).exists?
  end

  def self.count
    retryable do
      s3_objects.count
    end
  end

  def self.clear!
    retryable do
      s3_objects.each { |item| item.delete }
    end
  end

  def self.s3_objects
      s3 = AWS::S3.new(AWS_CREDENTIALS)
      s3.buckets[index_bucket_name].objects
  end

  def self.index_bucket_name
    "scoperrific-index" + ENV_BUCKET_POSTFIX
  end

  def self.url_for_image(image)
    Image.new(source: image).cdn_url
  end
end
