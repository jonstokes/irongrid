class DecoratePage
  include Interactor

  def perform
    context[:url] = page.url.to_s
    context[:doc] = DocReader.new(doc: page.doc, url: context[:url])
  end
end
