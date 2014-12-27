module Spree
  class Subscription < ActiveRecord::Base
    belongs_to :plan
    belongs_to :user, class_name: "::#{Spree.user_class.to_s}"

    before_create :set_subscribed_at
	def set_subscribed_at
	  self.subscribed_at = Time.now
	end

    
  end
end
