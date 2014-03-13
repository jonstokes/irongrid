ENV_BUCKET_POSTFIX = case Rails.env
      when "production"; ""
      when "development"; "-staging"
      when "staging"; "-staging"
      when "test"; "-test"
      when "cucumber"; "-test"
    end

IMAGE_PREFIX = "http://cache.scoperrific.com/"
TEST_IMAGE = "https://scoperrific-site.s3.amazonaws.com/test-image.png"

