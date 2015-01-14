require 'spec_helper'

def image_width(file_name)
  ImageVoodoo.with_image(file_name) do |img|
    img.width
  end
end

describe CDN::Image do
  before :each do
    @site = create_site "www.armslist.com"
    Mocktra(@site.domain) do
      get '/images/1.png' do
        send_file "#{Rails.root}/spec/fixtures/images/test-image.png"
      end
      get '/images/2.png' do
        send_file "#{Rails.root}/spec/fixtures/images/zero-bytes-image.png"
      end
      get '/images/3.png' do
        "<html><head></head><body>Image Not Found</body></html>"
      end
      get '/images/4.png' do
        404
      end
    end

    @image_source = "http://#{@site.domain}/images/1.png"
    @http = Sunbro::HTTP.new
    CDN.clear!
  end

  describe "::create" do
    it "pulls an image from the web, resizes it, and puts it on s3" do
      image = CDN::Image.create(source: @image_source, http: @http)
      expect(File.exists?(image.send(:temp_file_name))).to be_false
      expect(File.exists?(image.send(:thumb_file_name))).to be_false
      expect(image.exists?).to be_true
    end
  end

  describe "::exists?" do
    it "returns true if an image exists on s3" do
      image = CDN::Image.create(source: @image_source, http: @http)
      expect(CDN::Image.exists?(image.source)).to be_true
    end
  end

  describe "#new" do
    it "creates a new Image" do
      image = CDN::Image.new(source: @image_source)
      expect(image).to be_a(CDN::Image)
      expect(image.cdn_name).to eq("5dcff612e721d083a56fb6706f95bd7e.png")
    end

    it "raises an error if there's no source option" do
      expect {
        CDN::Image.new(foo: "bar")
      }.to raise_error(RuntimeError)
    end

    it "uses a worker's existing http connection in order to keep site loads low" do
      image = CDN::Image.new(source: @image_source, http: @http)
      expect(image.http).to eq(@http)
    end
  end

  describe "#cdn_url" do
    it "returns the image's url on the cdn" do
      image = CDN::Image.new(source: @image_source)
      expect(image.cdn_url).to eq("https://s3.amazonaws.com/scoperrific-index-test/5dcff612e721d083a56fb6706f95bd7e.png")
    end
  end

  describe "#resize" do
    it "resizes an image that's greater than 400px width" do
      image = CDN::Image.new(source: @image_source, http: @http)
      image.download
      image.resize
      expect(image.file_name).to eq(image.send(:thumb_file_name))
      expect(File.exists?(image.send(:temp_file_name))).to be_false
      expect(image_width(image.file_name)).to eq(400)

      image.delete_file!
    end
  end

  describe "#destroy!" do
    it "deletes a file from s3" do
      image = CDN::Image.new(source: @image_source, http: @http)
      image.download
      image.resize
      image.write_to_s3
      expect(image.exists?).to be_true
      image.destroy!
      expect(image.exists?).to be_false
    end
  end
  describe "#write_to_s3" do
    it "writes a downloaded file to s3" do
      image = CDN::Image.new(source: @image_source, http: @http)
      image.download
      image.resize
      image.write_to_s3
      expect(image.exists?).to be_true
      expect(File.exists?(image.file_name)).to be_false
    end
  end

  describe "#download_image" do
    it "requires an http connection" do
      image = CDN::Image.new(source: @image_source)
      expect {
        image.send(:download_image)
      }.to raise_error(RuntimeError)
    end

    it "downloads the image to a Sunbro::Page object if the image exists" do
      image = CDN::Image.new(source: @image_source, http: @http)
      expect(image.send(:download_image)).to be_a(Sunbro::Page)
      expect(image.page.image?).to be_true
    end

    it "returns nil if the downloaded object is not an image" do
      image = CDN::Image.new(source: "http://#{@site.domain}/images/3.png", http: @http)
      expect(image.send(:download_image)).to be_nil
    end

    it "returns nil if the image is not found" do
      image = CDN::Image.new(source: "http://#{@site.domain}/images/4.png", http: @http)
      expect(image.send(:download_image)).to be_nil
    end
  end

  describe "#write_to_file" do
    it "writes a downloaded image to a temp file" do
      image = CDN::Image.new(source: @image_source, http: @http)
      image.send(:download_image)
      expect(image.send(:write_to_file)).to eq(image.send(:temp_file_name))
      expect(File.exists?(image.send(:temp_file_name))).to be_true
      expect(File.size(image.send(:temp_file_name))).not_to be_zero
      expect(image.file_name).to eq(image.send(:temp_file_name))

      image.delete_file!
    end

    it "returns nil if the temp file is zero length" do
      pending "Figure out how to do this"
    end
  end
end
