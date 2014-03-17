class DeleteDeactivateListingsQueue < SuperQueue
  def initialize
    super(disable_s3: true, name: 'irongrid-delete-deactivate-listings-queue')
  end
end
