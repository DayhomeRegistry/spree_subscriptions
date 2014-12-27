Spree::Product.class_eval do
  has_many :plans, :through => :variants_including_master

  preference :subscription, :boolean

  def is_subscription?
  	preferred_subscription && plans.present?
  end

end