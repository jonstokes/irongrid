class DenormalizeForListing
  include Interactor

  def call
    context.denormalized_product = {
        upc:              context.product.upc,
        mpn:              context.product.mpn,
        sku:              context.product.sku,
        msrp:             context.product.msrp,
        category1:        context.product.category1,
        manufacturer:     context.product.manufacturer,
        caliber:          context.product.caliber,
        caliber_category: context.product.caliber_category,
        ammo_type:        context.product.ammo_type,
        number_of_rounds: context.product.number_of_rounds,
        material:         context.product.material,
        grains:           context.product.grains,
        shot_size:        context.product.shot_size,
        velocity:         context.product.velocity,
        load_type:        context.product.load_type,
        bullet_type:      context.product.bullet_type,
        shell_length:     context.product.shell_length
    }
  end
end