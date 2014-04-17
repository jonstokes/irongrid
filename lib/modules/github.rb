module Github
  def fetch_file_from_github(filename)
    branch = ENV['SITE_BRANCH'] || "master"
    url = "https://raw.github.com/jonstokes/ironsights-sites/#{branch}/#{filename}"
    puts "Fetching file from #{url}"
    open(url, http_basic_authentication: ["jonstokes", "2bdb479801fc520e3ae90a2aecd53be3a89cc2e1"]).read
  rescue OpenURI::HTTPError
    return nil
  end
end
