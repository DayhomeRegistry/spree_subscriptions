Spree::Order.class_eval do
  # all products are subscriptions
  def subscription?
    line_items.all? { |item| item.subscription? }
  end
  
  def some_subscription?
    line_items.any? { |item| item.subscription? }
  end

  def subscription_line_items
    line_items.select(&:subscription?)
  end

end
