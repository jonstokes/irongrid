class DeleteDeactivateListingsQueue < SuperQueue
  def initialize
    super(disable_s3: true, name: 'delete_deactivate_listings_queue')
  end
end
