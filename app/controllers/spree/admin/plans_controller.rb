module Spree
  module Admin
    class PlansController < ResourceController
      belongs_to "spree/product", :find_by => :slug
      before_action :load_data, only: [:new, :create, :edit, :update]
      
      # def index
      #   #@plans = @product.plans

        
      # end
      def new
        @plan = Spree::Plan.new
        
      end

      protected
        #

      def permitted_resource_params
        params.require(:plan).permit(permitted_plan_attributes)
      end

      def permitted_plan_attributes
        [:variant_id,:payment_method_id,:name]
      end

      def collection
        @deleted = (params.key?(:deleted) && params[:deleted] == "on") ? "checked" : ""

        if @deleted.blank?
          @collection ||= super
        else
          @collection ||= Plan.only_deleted.includes(:variant).where(spree_variants: {:product_id => parent.id})
        end
        @collection
      end

      private
      def load_data
        @payment_methods = []
        Spree::PaymentMethod.all.each do |method|          
          @payment_methods << method if method.subscriptions_supported?
        end
        @variants = @product.variants
      end
      
    end
  end
end
