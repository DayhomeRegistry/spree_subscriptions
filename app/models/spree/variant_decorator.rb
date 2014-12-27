Spree::Variant.class_eval do
  has_many :plans
  after_save :destroy_plans, :if => :deleted?
  
  # Is this variant a subscription?
  def is_subscription?
    product.is_subscription? 
  end
  
  private
  
  # :dependent => :destroy needs to be handled manually
  # spree does not delete variants, just marks them as deleted?
  # optionally keep subscriptions around for customers who require continued access to their purchases
  def destroy_plans
    plans.map &:destroy unless Spree::SubscriptionConfiguration[:keep_plans]
  end

end
Spree::ProductsHelper.module_eval do
  # returns the formatted price for the specified variant as a difference from product price
  def variant_price_diff(variant)
    variant_amount = variant.amount_in(current_currency)
    product_amount = variant.product.amount_in(current_currency)
    return if variant_amount == product_amount || product_amount.nil?
    if variant.is_subscription?
      diff = product_amount*12-variant_amount
      amount = Spree::Money.new(diff.abs, currency: current_currency).to_html
      "(#{Spree.t(:savings_of, scope: 'subscriptions')} #{amount})".html_safe
    else
      diff   = variant_amount - product_amount
      amount = Spree::Money.new(diff.abs, currency: current_currency).to_html
      label  = diff > 0 ? :add : :subtract
      "(#{Spree.t(label)}: #{amount})".html_safe
    end
  end
end
