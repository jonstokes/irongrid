require 'rubygems'
require 'aws-sdk'

begin
  AWS.eager_autoload! # for thread safety
rescue NameError
  retry
end

AWS.config(:logger => nil) if Rails.env.production?

AWS_CREDENTIALS = {
  access_key_id: Figaro.env.aws_access_key_id,
  secret_access_key: Figaro.env.aws_secret_access_key
}
