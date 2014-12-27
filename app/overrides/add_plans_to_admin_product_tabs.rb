Deface::Override.new(:virtual_path => "spree/admin/shared/_product_tabs",
                     :name => "add_digital_versions_to_admin_product_tabs",
                     :insert_bottom => "[data-hook='admin_product_tabs'], #admin_product_tabs[data-hook]",
                     :text => " <% if @product.is_subscription? %>   <li<%== ' class=\"active\"' if current == \"Plans\" %>>
      <%= link_to admin_product_plans_path(@product), class: 'fa fa-repeat icon_link with_tip' do %>
        <span class=\"text\"><%= Spree.t(:plans, scope: 'subscriptions') %></span>
      <% end %>
    </li> <% end %>
",
                     :disabled => false)

Deface::Override.new(:virtual_path => "spree/checkout/edit",
                     :name => "add_paypal_token_to_form",
                     :insert_after => "erb[loud]:contains('form_for')",#{}"#checkout_form_confirm",
                     :text => "<input name='order[pay_pal_token]' id='order_pay_pal_token' type='hidden' value='<%=params[\'token\']%>'><input name='order[pay_pal_payer_id]' id='order_pay_pal_payer_id' type='hidden' value='<%=params[\'PayerID\']%>'>",
                     :disabled => false)