class DeleteListingsQueue < SuperQueue
  def initialize
    super(disable_s3: true, name: 'irongrid-delete-listings-queue')
  end
end
