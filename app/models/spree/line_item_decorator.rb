Spree::LineItem.class_eval do
  
  has_many :subscriptions, :dependent => :destroy
  
  def subscription?
    variant.subscription?
  end
  
  private
  
  

  
end
