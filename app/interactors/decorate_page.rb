class DecoratePage
  include Interactor

  def setup
    context.fail! unless page && page.doc
  end

  def perform
    context[:url] = page.url
    context[:doc] = DocReader.new(doc: page.doc, url: context[:url]
  end
end
