class ScriptRunner

  attr_reader :attributes

  def initialize
    @attributes = {}
  end

  def method_missing(name, *args, &block)
    if block_given?
      attributes[name.to_s] = block
    else
      attributes[name.to_s] = args[0]
    end
  rescue RuntimeError => e
    if !!e.message[/add a new key into hash during iteration/]
      super
    else
      raise e
    end
  end

end
