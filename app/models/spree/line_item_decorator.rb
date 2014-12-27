Spree::LineItem.class_eval do
  
  # has_many :subscriptions, :dependent => :destroy
  
  def is_subscription?
    variant.is_subscription?
  end
  
  private
  
  

  
end
