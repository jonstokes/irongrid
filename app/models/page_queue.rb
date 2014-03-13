class PageQueue < SuperQueue
  def initialize
    super(name: "irongrid-page-queue")
  end
end
