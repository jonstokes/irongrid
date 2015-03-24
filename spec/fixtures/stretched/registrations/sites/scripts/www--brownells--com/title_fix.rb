Stretched::Script.define "www.brownells.com/title_fix" do
  extensions 'globals/extensions/*'
  script do
    title do |instance|
      xpath = "//section[@class='pageContent']/section[@class='main']/div[@id='listMain']/section[@class='itemSummary mbm']/div[@class='wrap']/h1[@class='mbm']"
      "#{instance.title} #{find_by_xpath(xpath: xpath)}".strip
    end
  end
end
