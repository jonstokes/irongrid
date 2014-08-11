def scrub(content)
  if category1["category1"] == "Optics"
    ProductDetails::Scrubber.scrub(content, :inches, :punctuation, :color)
  else
    ProductDetails::Scrubber.scrub_all(content)
  end
end

set "title" do
  raw = context[:title]["title"]
  {
    "title" => raw,
    "scrubbed" => scrub(raw),
    "autocomplete" => raw
  }
end

set "keywords" do
  return unless raw = context[:keywords]["keywords"]
  {
    "keywords" => raw,
    "scrubbed" => scrub(raw)
  }
end

