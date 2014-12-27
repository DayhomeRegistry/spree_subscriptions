module Spree
  class SpreeSubscriptionsConfiguration < Preferences::Configuration
    # flag to determine if a person can subscribe to the same variant more than once
    preference :allow_duplicate_subscription,  :boolean, :default => false
  end
end