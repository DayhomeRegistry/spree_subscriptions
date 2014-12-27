Spree.user_class.class_eval do
	has_many :subscriptions, class_name: "::Spree::Subscription"

	def has_subscription(variant)
		matches = subscriptions.select{|subscription| subscription.plan.variant.product==variant.product}
		matches.count > 0
	end
end