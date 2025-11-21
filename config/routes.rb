Rails.application.routes.draw do
  # Sidekiq Web UI (add authentication in production!)
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
  
  devise_for :users, path: '', path_names: {
    sign_in: 'login',
    sign_out: 'logout',
    registration: 'signup'
  }, 
  controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations',
  }, defaults: { format: :json }
  
  # Webhooks
  post 'webhooks' => 'webhooks#create', as: :webhooks
  
  # Public endpoints pentru sesiunile de masă
  get 't/:slug' => 'bill_sessions#create_session', as: :create_bill_session
  get 'session/:session_token' => 'bill_sessions#show_session', as: :show_bill_session
  post 'validate_qr_token' => 'bill_sessions#validate_qr_token', as: :validate_qr_token
  
  # Endpoints pentru bills (necesită sesiune validă)
  get 'bills' => 'bills#show', as: :show_bill
  patch 'bills/update_tip' => 'bills#update_tip', as: :update_bill_tip
  
  namespace :users do
    #PAYMENTS
    post 'payment/create_payment' => 'payments#create_payment'
    post 'payment/pay_bill' => 'payments#pay_bill'
    post 'payment/send_receipt' => 'payments#send_receipt'
    
    #ITEM_TABLE_RELATIONS
    get 'item_table_relations' => 'item_table_relations#index'
  end
end
