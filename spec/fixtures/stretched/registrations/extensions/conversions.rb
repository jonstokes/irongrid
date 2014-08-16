Stretched::Extension.define do
  extension "conversions" do
    def convert_dollars_to_cents(result)
      result.slice!("$")
      result.slice!(".")
      result.to_i
    end
  end
end
