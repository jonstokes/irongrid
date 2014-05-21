module Github
  def fetch_file_from_github(filename)
    branch = ENV['SITE_BRANCH'] || "master"
    url = "https://raw.githubusercontent.com/jonstokes/ironsights-sites/#{branch}/#{filename}"
    puts "Fetching file from #{url}"
    open(url, http_basic_authentication: ["jonstokes", Figaro.env.github_token]).read
  rescue OpenURI::HTTPError
    return nil
  end
end
