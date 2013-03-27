Litchfield::Application.routes.draw do |map|
  devise_for :users do
	# make the routes shorter. Also, this is a workaround for a bug that crashes when the base url is "/ledger"
	get "/sign_in" => "devise/sessions#new"
	#match "sign_up" => "patched_registrations#new"
	#map.sign_up "/sign_up", :controller => "devise/registrations", :action => "new"
	get "/sign_out" => "devise/sessions#destroy"
  end
  match 'sign_up' => 'admin#new_user'
  match '/create_user', :to => 'admin#create_user', :via => :post
  match 'edit_user' => 'admin#edit_user'
  match '/update_user', :to => 'admin#update_user', :via => :post
  match '/destroy_user', :to => 'admin#destroy_user', :via => :post
	map.user_root '/admin', :controller => 'admin' # creates user_root_path

  get 'contact_us' => 'home#contact_us'
  post 'home/mail' => 'home#mail'

  match 'admin/validate_date' => 'admin#validate_date'

  match 'search/advanced' => 'search#advanced'
  match 'search/autocomplete' => 'search#autocomplete'
  match 'browse' => 'browse#index'
  match 'search' => 'search#index'
  match 'search/help' => 'search#help'
  match 'about' => 'search#about'
  match 'studies' => 'studies#index'
  match 'studies/history' => 'studies#history'
  match 'studies/history_school' => 'studies#history_school'
  match 'studies/history_lfa' => 'studies#history_lfa'
  match 'studies/lls_bibliography' => 'studies#lls_bibliography'
  match 'studies/lfa_bibliography' => 'studies#lfa_bibliography'
  match 'admin' => 'admin#index'
  match 'students/why' => 'students#why'
  match 'students/limit' => 'students#limit'
  match 'admin/new_row' => 'admin#new_row'

  match 'test_exception_notifier' => 'application#test_exception_notifier'

  match 'students/export_data' => 'students#export_data'
  match 'materials/export_data' => 'materials#export_data'
  match 'admin/account_maintenance' => 'admin#account_maintenance'
  post 'materials/add_transcription/:id' => 'materials#add_transcription'
  post 'materials/add_image/:id' => 'materials#add_image'
  post 'materials/remove_transcription/:id' => 'materials#remove_transcription'
  post 'materials/remove_image/:id' => 'materials#remove_image'

  # after logging it, this is the page to go to
  resources :admin
  #get '/admin' => 'admin#index'

  resources :materials

  resources :students

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get :short
  #       post :toggle
  #     end
  #
  #     collection do
  #       get :sold
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get :recent, :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => "home#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
