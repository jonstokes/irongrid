class DeactivateListingsQueue < SuperQueue
  def initialize
    super(disable_s3: true, name: 'irongrid-deactivate-listings-queue')
  end
end
