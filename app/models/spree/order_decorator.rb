Spree::Order.class_eval do

  def validate
    self.errors.add_to_base(@variant_errors) unless @variant_errors.nil?
  end
  
  def add_variant(variant, quantity = 1)
    if variant.nil? || (!variant.in_stock? && !Spree::Config[:allow_backorders])
      @variant_errors = I18n.t('variant_out_of_stock') 
    else
      self.add_variant_original(variant, quantity)
    end
  end
  alias_method :add_variant_original, :add_variant
  alias_method :validate_original, :validate
  
  attr_accessor :redirect_to, :pay_pal_token, :pay_pal_payer_id


  def subscription_line_items
    line_items.select(&:is_subscription?)
  end

  def has_subscription?
    has_subscription = false
    self.line_items.each do |line_item|
      has_subscription ||= line_item.variant.is_subscription?
    end
    has_subscription
  end
  def payment_required?
    !self.has_subscription? # && super
  end
  def requires_redirect?
    line_item = validate_subscription_state()
    product = line_item.variant.product
    if(!payments.empty?)
      plan = Spree::Plan.where(variant_id: line_item.variant.id, payment_method_id: payments.first.payment_method_id).first
      plan.requires_redirect? || false
    else
      false
    end
  end

  checkout_flow do
    go_to_state :address
    go_to_state :subscription, if: ->(order) { order.has_subscription? }
    go_to_state :payment, if: ->(order) { order.payment_required? }
    go_to_state :confirm, if: ->(order) { order.confirmation_required? }
    go_to_state :complete

  end
  #Stripe will use the default credit card parameters to create the customer profile
  #PayPal will create a payment source after confirm since it needs the payer_id from the transaction
  #In confirm, we need to check the payment method and then call subscribe on it.
  state_machine.before_transition :from => :subscription, :do => :customer_profile
  state_machine.before_transition :from => :confirm, :do => :subscribe

  def customer_profile
    line_item = validate_subscription_state()

    product = line_item.variant.product
    plan = Spree::Plan.where(variant_id: line_item.variant.id, payment_method_id: payments.first.payment_method_id).first
    if(plan.nil?)
      raise Spree::Core::GatewayError.new "This payment method isn't setup for subscriptions."
    end

    self.redirect_to=""
    if plan.requires_redirect?
      self.redirect_to= plan.build_customer_profile(self)
    else
      plan.build_customer_profile(self) #self is the order
    end

  end
  
  def after_subscribe
  end
  def subscribe
    line_item = validate_subscription_state()

    product = line_item.variant.product
    if(product.upgrade_froms.count==1)
      #Check if the current user has the previous level
      subscriptions = self.user.subscriptions
      unless subscriptions.index{|item| item.unsubscribed_at.nil? && item.plan.variant.product==product.upgrade_froms.first}.nil?
        #unsubscribe from the lower level
        old_one = subscriptions[subscriptions.index{|item| item.unsubscribed_at.nil? && item.plan.variant.product==product.upgrade_froms.first}]
        old_one.plan.unsubscribe(self,old_one)
        old_one.unsubscribed_at = Time.now()
        old_one.save
      end

    end
    plan = Spree::Plan.where(variant_id: line_item.variant.id, payment_method_id: payments.first.payment_method_id).first
    if(plan.nil?)
      raise "This payment method isn't supported."
    end
    plan.subscribe(self) #self is the order
    after_subscribe()
  end
  
  def after_unsubscribe
  end
  def unsubscribe

    after_unsubscribe()
  end

  private
  def validate_subscription_state
    # there should only be one
    items = subscription_line_items
    if(items.count>1)
      raise "You shouldn't have more than one subscription in the cart at once."
    end
    if(items.count==0)
      raise "There are no plans associated with this subscription.  Please contact your administrator."
    end
    items.first
  end


end
