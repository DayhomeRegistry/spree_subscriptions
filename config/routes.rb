Spree::Core::Engine.routes.draw do
  namespace :admin do
    
    resources :products do
      resources :plans
    end

  end
  
end
