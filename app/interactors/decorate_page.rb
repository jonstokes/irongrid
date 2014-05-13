class DecoratePage
  include Interactor

  def perform
    if context[:page]
      context[:url] ||= page.url.to_s
      context[:doc] = DocReader.new(doc: page.doc, url: context[:url])
    else
      context[:doc] = DocReader.new(doc: context[:doc], url: context[:url])
    end
  end
end
