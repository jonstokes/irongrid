require 'digest/md5'

FactoryGirl.define do
  factory :page, :class => PageUtils::Page do
    url { "http://www.foo.com/#{Digest::MD5.hexdigest(Faker::Lorem.paragraph)}.html" }
    body do
      File.read("features/test_html/New Ruger LCP .380 299.00 SHIPS FREE.html") + "<!--" + Faker::Lorem.paragraph + "-->"
    end

    initialize_with { new(attributes[:url], { :body => attributes[:body]}) }
  end
end
