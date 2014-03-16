class ParsedPageQueue < SuperQueue
  def initialize
    super(disable_s3: true, name: 'irongrid-parsed-page-queue')
  end
end
