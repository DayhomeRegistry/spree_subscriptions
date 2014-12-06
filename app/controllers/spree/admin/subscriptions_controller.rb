module Spree
  module Admin
    class SubscriptionsController < ResourceController
      belongs_to "spree/product", :find_by => :slug
      
      protected
        #

      def permitted_resource_params
        params.require(:subscription).permit(permitted_subscription_attributes)
      end

      def permitted_subscription_attributes
        [:variant_id, :plan_id]
      end
    end
  end
end
