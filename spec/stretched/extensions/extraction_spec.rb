require 'spec_helper'

describe "extraction.rb" do
  before :each do
    Stretched::Registration.with_redis { |c| c.flushdb }
    register_globals
    Stretched::Extension.register_all

    @runner = Stretched::ScriptRunner.new

    # Define all extensions on the runner instance
    Stretched::Extension.registry.each_pair do |extname, block|
      @runner.instance_eval(&block)
    end
  end

  describe "extract_grains" do
    it "extracts grains from a string" do
      result = @runner.extract_grains("9mm FMJ 62gr")
      expect(result).to eq("62")

      result = @runner.extract_grains("9mm FMJ 62 gr")
      expect(result).to eq("62")

      result = @runner.extract_grains("9mm FMJ 62-gr")
      expect(result).to eq("62")

      result = @runner.extract_grains("9mm FMJ 62 grain")
      expect(result).to eq("62")

      result = @runner.extract_grains("9mm FMJ 62 grains")
      expect(result).to eq("62")
    end
  end

  describe "extract_number_of_rounds" do
    it "should extract the number of rounds from a string" do
      pending "Example"
    end
  end

end
