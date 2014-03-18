require 'mocktra'

# define stub
Mocktra('www.retailer.com') do
  get '/products' do
    File.open("#{Rails.root}/spec/fixtures/web_pages/www--retailer--com/products.html") do |file|
      file.read
    end
  end
end

