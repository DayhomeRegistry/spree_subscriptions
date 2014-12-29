Spree::OrdersController.class_eval do
  before_action :add_variants_from_drop_downs, only: :create

  def add_variants_from_drop_downs
    if params[:option_types] and params[:product]
      variant = Variant.find_by_option_types_and_product(params[:option_types], params[:product])
      quantity = params[:quantity].to_i
      @object.add_variant(variant, quantity) if quantity > 0
    end
  end      
end