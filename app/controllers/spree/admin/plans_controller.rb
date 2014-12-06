module Spree
  module Admin
    class PlansController < ResourceController
      
      protected
        #

      def permitted_resource_params
        params.require(:plan).permit(permitted_plan_attributes)
      end

      def permitted_subscription_attributes
        [:plan_id]
      end
    end
  end
end
