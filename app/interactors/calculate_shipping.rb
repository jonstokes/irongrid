class CalculateShipping
  include Interactor::Organizer

  organize [
    Shipping::SetShippingCost,
    Shipping::SetShippingAttributes,
  ]

end
