module OrderPopulatorExtensions
  # def update
  #   do_before_work
  #   super
  #   do_after_work
  # end

  protected
  # def do_before_work
  #   # do something interesting before super
  # end
  # def do_after_work
  #   # do something interesting after super
  # end
  def attempt_cart_add(variant_id, quantity, options = {})
    if ensure_empty_cart_for_subscription(variant_id) 
      return super
    end
    return false
  end

  def ensure_empty_cart_for_subscription(variant_id)
    variant = Spree::Variant.find(variant_id)
    if (variant.is_subscription? && @order.item_count>0) || @order.has_subscription?
        errors.add(:base, Spree.t(:subscriptions_must_be_purchased_separately, scope: :order_populator))
        return false
    end
    byebug
    if(!Spree::SubscriptionsConfiguration[:allow_duplicate_subscription])
      #check here to see if they have a subscription
      if(@order.user)
        if(@order.user.has_subscription(variant))
          errors.add(:base, Spree.t(:subscription_duplicate, scope: :order_populator))
          return false
        end
      end
    end
    return true
  end
end

Spree::OrderPopulator.class_eval do
  prepend OrderPopulatorExtensions
end