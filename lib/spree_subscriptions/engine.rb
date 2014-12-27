module SpreeSubscriptions
  class Engine < Rails::Engine
    engine_name 'spree_subscriptions'

    config.autoload_paths += %W(#{config.root}/lib)

    initializer "spree.spree_subscriptions.preferences", :after => "spree.environment" do |app|
      Spree::SpreeSubscriptionsConfiguration = Spree::SpreeSubscriptionsConfiguration.new
    end
    initializer "spree.spree_subscriptions.subscription_providers", :after => "spree.register.payment_methods" do |app|
      app.config.spree.add_class('subscription_providers')
      app.config.spree.subscription_providers << Spree::CreditCard
      app.config.spree.subscription_providers << Spree::PaypalExpressCheckout
    end

    # initializer "spree.register.digital_shipping", :after => 'spree.register.calculators' do |app|
    #   app.config.spree.calculators.shipping_methods << Spree::Calculator::Shipping::DigitalDelivery
    # end

    # initializer 'spree_subscriptions.custom_spree_splitters', :after => 'spree.register.stock_splitters' do |app|
    #   app.config.spree.stock_splitters << Spree::Stock::Splitter::Digital
    # end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), "../../app/**/*_decorator*.rb")) do |c|
        Rails.application.config.cache_classes ? require(c) : load(c)
      end
    end

    config.to_prepare &method(:activate).to_proc
  end
end
