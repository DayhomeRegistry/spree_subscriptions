module Spree
  class Subscription < ActiveRecord::Base
    belongs_to :variant
    belongs_to :plan

    
  end
end
