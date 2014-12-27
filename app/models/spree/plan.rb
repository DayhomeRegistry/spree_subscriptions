module Spree
  class Plan < Spree::Base
  	acts_as_paranoid

  	belongs_to :variant
  	belongs_to :payment_method
    #has_many :subscriptions
    validates_uniqueness_of :variant_id, scope: :payment_method_id, allow_blank: false, conditions: -> { where(deleted_at: nil) }
    
    before_create :create_plan
    before_save :update_plan, unless: :new_record?
    before_destroy :delete_plan

    INTERVAL = { week: 'Weekly', month: 'Monthly', year: 'Annually' }
    CURRENCY = { cad: 'CAD'}
	
		def deleted?
      !!deleted_at
    end
    def requires_redirect?
    	provider.requires_redirect?
    end
    def description_or_default
    	self.description || "Subscription"
    end

    def raise_invalid_order_error(order)
      raise "Not a valid order." unless order.is_a?(Spree::Order) && order.has_subscription?
    end
    def build_customer_profile(order)
    	raise_invalid_order_error(order)
    	return provider.create_customer_profile(order,self)
    end
    def subscribe(order)
	    raise_invalid_order_error(order)
	    # pass the order so the provider can get the customer (if necessary), and the plan for the plan_api_id
	    provider.subscribe(order, self)

	    #OK, so we successfully subscribed.
	    # begin
	    #   #Now let's record the credit card
	    #   byebug
	    #   payment_method = 
	    #   customer = @subscription.user.find_or_create_stripe_customer()
	    #   card = customer.cards.first  
	    #   spree_card = Spree::CreditCard.find_by(:gateway_payment_profile_id=>customer.cards.first.id)
	    #   if(spree_card.nil?)
	    #     Spree::CreditCard.create(
	    #           month: card.exp_month,
	    #           year: card.exp_year,
	    #           cc_type: 'master',
	    #           last_digits: card.last4,
	    #           name: card.name,
	    #           payment_method_id: 1, #Need to work on this one
	    #           gateway_customer_profile_id: customer.id,
	    #           gateway_payment_profile_id: customer.cards.first.id,
	    #           user_id: spree_current_user.id
	    #         )
	    #   end 
	    # rescue => e
	    #   #Just catch everything and log
	    #   logger.error e.message
	    #   e.backtrace.each { |line| logger.error line }
	    # end
	  end

	  def unsubscribe(order, subscription)
	    raise_invalid_order_error(order)
	    # pass the order so the provider can get the customer (if necessary), and the plan for the plan_api_id
	    provider.unsubscribe(order, subscription)
	  end

	  def provider
	  	self.payment_method
	  end
	  def create_plan
	  	set_api_plan_id
	  	provider.create_plan(self)
	  end
	  def update_plan
	  	provider.update_plan(self)
	  end
	  def delete_plan
	  	provider.delete_plan(self)
	  end

	  private

      def set_api_plan_id
        provider.set_api_plan_id(self)
      end
  end
end
