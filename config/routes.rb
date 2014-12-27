Spree::Core::Engine.routes.draw do
  
  #mount StripeEvent::Engine, at: '/subscription/web-hooks' # provide a custom path
  
  namespace :admin do
    
    resources :products do
      resources :plans do
      	collection do
   		  post :update_positions
   		end
   	  end
    end
  end
end
