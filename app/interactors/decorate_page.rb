class DecoratePage
  include Interactor

  def perform
    context[:url] = page.url
    context[:doc] = DocReader.new(doc: page.doc, url: context[:url]
  end
end
