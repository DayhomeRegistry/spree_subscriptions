Spree::Product.class_eval do
  has_many :subscriptions, :through => :variants_including_master
end