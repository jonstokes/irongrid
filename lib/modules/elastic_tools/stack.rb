module ElasticTools
  class Stack
    attr_reader :elements

    def initialize
      @elements = []
    end

    def length
      @elements.length
    end

    def push(x)
      @elements.push x
      self
    end

    def swap(x=nil)
      if x
       self.pop
        self.push(x)
      else
        b = self.pop
        a = self.pop
        self.push(b)
        self.push(a)
      end
    end

    def pop
      @elements.pop
    end

    def peek
      @elements[-1]
    end
  end
end
