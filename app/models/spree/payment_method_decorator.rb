Spree::PaymentMethod.class_eval do
    def subscriptions_supported?
      false
    end

end
Spree::Gateway::StripeGateway.class_eval do
	  def subscriptions_supported?
    	true
    end
    def requires_redirect?
      false
    end

    def error_class
      Stripe::InvalidRequestError
    end

    def raise_invalid_object_error(object, type)
      raise error_class.new("Not a valid object.") unless object.is_a?(type)
    end

    def create_plan(plan)
	    raise_invalid_object_error(plan, Spree::Plan)
      intervalType = Spree::OptionType.where(name: "interval").first

      intervalValue = plan.variant.product.variants.includes(:option_values).where(id: plan.variant.id).first.option_values.where(option_type_id: intervalType.id).first

	    Stripe::Plan.create(
	      amount: stripe_amount(plan.variant.price),
	      interval: intervalValue.name,
	      interval_count: 1,
	      name: plan.name,
	      currency: plan.variant.currency,
	      id: plan.api_plan_id,
	      trial_period_days: 0
	    )
  	end

  	def delete_plan(plan)
  	    raise_invalid_object_error(plan, Spree::Plan)
  	    stripe_plan = retrieve_api_plan(plan)
  	    stripe_plan.delete
  	end

    def update_plan(plan)
      raise_invalid_object_error(plan, Spree::Plan)
      stripe_plan = retrieve_api_plan(plan)
      stripe_plan.name = plan.name
      stripe_plan.save
    end

    def set_api_plan_id(plan)
      plan.api_plan_id = plan.name+"-#{Time.current.to_i}"
    end

    def create_customer_profile(order,plan)
      # the default gateway methods invoked by the checkout process do this just fine
      # do nothing here.

    end
    
    def subscribe(order,plan)
      customer_id = order.payments.first.source.gateway_customer_profile_id
      customer = Stripe::Customer.retrieve(customer_id)
      sub = customer.subscriptions.create(:plan => plan.api_plan_id)
      Spree::Subscription.create(
        plan: plan,
        user: order.user,
        api_sub_id: sub.id
      )

    end
    def unsubscribe(order,subscription)
      byebug
      customer_id = order.payments.first.source.gateway_customer_profile_id
      customer = Stripe::Customer.retrieve(customer_id)
      sub = customer.subscriptions.retrieve(subscription.api_sub_id)
      response = sub.delete
    end

    private

    def retrieve_api_plan(plan)
      Stripe::Plan.retrieve(plan.api_plan_id)
    end

    def stripe_amount(amount)
      (amount * 100).to_i
    end 


end	
Spree::Gateway::PayPalExpress.class_eval do
    include Spree::CheckoutHelper

    def subscriptions_supported?
      true
    end
    def requires_redirect?
      true
    end

    # Here are a whole set of empty methods since PayPal doesn't play this way
    def set_api_plan_id(plan)
    end
    def create_plan(plan)
    end
    def delete_plan(plan)
    end
    def update_plan(plan)
    end

    #And here is the real work
    def create_customer_profile(order,plan)
      raise_invalid_object_error(order, Spree::Order)
      raise_invalid_object_error(plan, Spree::Plan)
      items = order.line_items.map(&method(:line_item))

      tax_adjustments = order.all_adjustments.tax.additional
      shipping_adjustments = order.all_adjustments.shipping

      order.all_adjustments.eligible.each do |adjustment|
        next if (tax_adjustments + shipping_adjustments).include?(adjustment)
        items << {
          :Name => adjustment.label,
          :Quantity => 1,
          :Amount => {
            :currencyID => order.currency,
            :value => adjustment.amount
          }
        }
      end

      # Because PayPal doesn't accept $0 items at all.
      # See #10
      # https://cms.paypal.com/uk/cgi-bin/?cmd=_render-content&content_ID=developer/e_howto_api_ECCustomizing
      # "It can be a positive or negative value but not zero."
      items.reject! do |item|
        item[:Amount][:value].zero?
      end

      provider = plan.payment_method.provider
      pp_request = provider.build_set_express_checkout(subscription_checkout_request_details(order, plan, items))


      begin
        pp_response = provider.set_express_checkout(pp_request)
        if pp_response.success?
          order.payments.create!({
            :source => Spree::PaypalExpressCheckout.create(),
            :amount => order.total,
            :payment_method => plan.payment_method
          })
          return provider.express_checkout_url(pp_response, :useraction => 'commit')
        else
          raise Spree::Core::GatewayError.new Spree.t('flash.generic_error', :scope => 'paypal', :reasons => pp_response.errors.map(&:long_message).join(" "))
        end
      rescue SocketError
        raise Spree::Core::GatewayError.new Spree.t('flash.connection_failed', :scope => 'paypal')
      end
    end
    
    def subscribe(order,plan)
      provider = plan.payment_method.provider
      pp_details_request = provider.build_get_express_checkout_details({
          :Token => order.pay_pal_token#express_checkout.token
        })
        pp_details_response = provider.get_express_checkout_details(pp_details_request)
        pp_request = provider.build_create_recurring_payments_profile({
        :CreateRecurringPaymentsProfileRequestDetails => {
          :Token => pp_details_response.get_express_checkout_details_response_details.token,
          :PayerID => pp_details_response.get_express_checkout_details_response_details.PayerInfo.PayerID,
          :PaymentDetails => pp_details_response.get_express_checkout_details_response_details.PaymentDetails,
          :RecurringPaymentsProfileDetails => {
            :BillingStartDate => (Date.today).to_json 
          },
          :ScheduleDetails => {
            :Description => plan.description_or_default,#"Dayhome Registry Annual Subscription",
            :PaymentPeriod => {
              :BillingPeriod => "Year",
              :BillingFrequency => 1,
              :Amount => {
                :currencyID => "CAD",
                :value => pp_details_response.get_express_checkout_details_response_details.PaymentDetails.first.OrderTotal.value
              }
            },
            :ActivationDetails => {
              :InitialAmount=> {
                :currencyID => "CAD",
                :value => pp_details_response.get_express_checkout_details_response_details.PaymentDetails.first.OrderTotal.value
              } ,
              :FailedInitAmountAction=>"CancelOnFailure"
            }
          } 
        } 
      })
  
      raise_invalid_object_error(order, Spree::Order)
      pp_response = provider.create_recurring_payments_profile(pp_request)
      if !pp_response.success?
        order.state = order.state_changes.last.previous_state
        raise Spree::Core::GatewayError.new pp_response.errors.map(&:long_message).join(" ")
      end
      byebug
      Spree::Subscription.create(
        plan: plan,
        user: order.user,
        api_sub_id: pp_response.CorrelationID
      )
      payment = order.payments.last
      if payment.source.token.nil?
        payment.source.update_attributes({
          :token => order.pay_pal_token,
          :payer_id => order.pay_pal_payer_id,
          :transaction_id => pp_response.CorrelationID
        })
      end
    end

    def unsubscribe(order,subscription)

    end

    private 

    def raise_invalid_object_error(object, type)
      raise error_class.new("Not a valid object.") unless object.is_a?(type)
    end
    def subscription_checkout_request_details order, plan, items
      root = Rails.application.routes.url_helpers.root_url
      state = Spree::Core::Engine.routes.url_helpers.checkout_state_path(order.checkout_steps[order.checkout_steps.index(order.state)+1])
      { :SetExpressCheckoutRequestDetails => {
          :InvoiceID => order.number,
          :BuyerEmail => order.email,
          :ReturnURL => root+state,#subscribe_paypal_url(:payment_method_id => params[:payment_method_id], :utm_nooverride => 1),
          :CancelURL =>  root+state,#cancel_paypal_url,
          :SolutionType => plan.payment_method.preferred_solution.present? ? plan.payment_method.preferred_solution : "Mark",
          :LandingPage => plan.payment_method.preferred_landing_page.present? ? plan.payment_method.preferred_landing_page : "Billing",
          :cppheaderimage => plan.payment_method.preferred_logourl.present? ? plan.payment_method.preferred_logourl : "",
          :NoShipping => 1,
          :PaymentDetails => [payment_details(order,plan, items)],
          :BillingAgreementDetails => {
            :BillingType => "RecurringPayments",
            :BillingAgreementDescription => plan.description_or_default,#"Dayhome Registry Annual Subscription"
          }
      }}
    end
    def line_item(item)
      {
          :Name => item.product.name,
          :Number => item.variant.sku,
          :Quantity => item.quantity,
          :Amount => {
              :currencyID => item.order.currency,
              :value => item.price
          },
          :ItemCategory => "Digital"
      }
    end
    def payment_details order, plan, items
      # This retrieves the cost of shipping after promotions are applied
      # For example, if shippng costs $10, and is free with a promotion, shipment_sum is now $10
      shipment_sum = order.shipments.map(&:discounted_cost).sum

      # This calculates the item sum based upon what is in the order total, but not for shipping
      # or tax.  This is the easiest way to determine what the items should cost, as that
      # functionality doesn't currently exist in Spree core
      item_sum = order.total - shipment_sum - order.additional_tax_total

      if item_sum.zero?
        # Paypal does not support no items or a zero dollar ItemTotal
        # This results in the order summary being simply "Current purchase"
        {
          :OrderTotal => {
            :currencyID => order.currency,
            :value => order.total
          }
        }
      else
        {
          :OrderTotal => {
            :currencyID => order.currency,
            :value => order.total
          },
          :ItemTotal => {
            :currencyID => order.currency,
            :value => item_sum
          },
          :ShippingTotal => {
            :currencyID => order.currency,
            :value => shipment_sum,
          },
          :TaxTotal => {
            :currencyID => order.currency,
            :value => order.additional_tax_total
          },
          :ShipToAddress => address_options(order,plan),
          :PaymentDetailsItem => items,
          :ShippingMethod => "Subscription",
          :PaymentAction => "Sale"
        }
      end
    end
    def address_options order, plan
      return {} unless plan.payment_method.preferred_solution.eql?('Sole') #address required

      {
          :Name => order.bill_address.try(:full_name),
          :Street1 => order.bill_address.address1,
          :Street2 => order.bill_address.address2,
          :CityName => order.bill_address.city,
          :Phone => order.bill_address.phone,
          :StateOrProvince => order.bill_address.state_text,
          :Country => order.bill_address.country.iso,
          :PostalCode => order.bill_address.zipcode
      }
    end

end 