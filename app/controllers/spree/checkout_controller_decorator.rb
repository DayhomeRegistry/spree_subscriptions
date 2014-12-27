Spree::PermittedAttributes.module_eval do
  class_variable_set(:@@payment_attributes, class_variable_get(:@@payment_attributes).push(:pay_pal_token))
end
Spree::CheckoutController.class_eval do
  # New state
  def before_subscription
    if try_spree_current_user && try_spree_current_user.respond_to?(:payment_sources)
      @payment_sources = try_spree_current_user.payment_sources
    end
  end
  def before_confirm
		if(@order.requires_redirect?)
			if(
					(!params[:order] && (params[:token].nil? || params[:PayerID].nil?)) ||
					(params[:order] && (params[:order][:pay_pal_token].nil? || params[:order][:pay_pal_payer_id].nil?))
				)
				raise Spree::Core::GatewayError.new "PayPal confirmation token missing or invalid.  Please return to the 'Subscription' step to try again or choose another payment method"
			end
		end
  end
  # Updates the order and advances to the next state (when possible.)
	def update
		pp = permitted_checkout_attributes 
		pp<< :pay_pal_token
		pp<< :pay_pal_payer_id	
		
		if @order.update_from_params(params, pp, request.headers.env)
	    @order.temporary_address = !params[:save_user_address]

	    unless @order.next
	      flash[:error] = @order.errors.full_messages.join("\n")
	      redirect_to checkout_state_path(@order.state) and return
	    end

	    if @order.respond_to?(:requires_redirect?) && @order.requires_redirect? && @order.redirect_to
	    	redirect_to @order.redirect_to and return
	    end

	    if @order.completed?
	      @current_order = nil
	      flash.notice = Spree.t(:order_processed_successfully)
	      flash['order_completed'] = true
	      redirect_to completion_route
	    else
	      redirect_to checkout_state_path(@order.state)
	    end
	  else
	    render :edit
	  end
	end
	private
	def custom_attributes
		"[:coupon_code, :email, :shipping_method_id, :special_instructions, :use_billing, {:bill_address_attributes=>[:id, :firstname, :lastname, :first_name, :last_name, :address1, :address2, :city, :country_id, :state_id, :zipcode, :phone, :state_name, :alternative_phone, :company, {:country=>[:iso, :name, :iso3, :iso_name], :state=>[:name, :abbr]}], :ship_address_attributes=>[:id, :firstname, :lastname, :first_name, :last_name, :address1, :address2, :city, :country_id, :state_id, :zipcode, :phone, :state_name, :alternative_phone, :company, {:country=>[:iso, :name, :iso3, :iso_name], :state=>[:name, :abbr]}], :payments_attributes=>[:amount, :payment_method_id, :payment_method, {:source_attributes=>[:number, :month, :year, :expiry, :verification_value, :first_name, :last_name, :cc_type, :gateway_customer_profile_id, :gateway_payment_profile_id, :last_digits, :name, :encrypted_data]}], :shipments_attributes=>[:order, :special_instructions, :stock_location_id, :id, :tracking, :address, :inventory_units, :selected_shipping_rate_id]}]"
	end
end