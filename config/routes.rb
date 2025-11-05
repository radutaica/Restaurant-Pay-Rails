Rails.application.routes.draw do
  devise_for :users, path: '', path_names: {
    sign_in: 'login',
    sign_out: 'logout',
    registration: 'signup'
  }, 
  controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations',
  }, defaults: { format: :json }
  
  # Public endpoints pentru sesiunile de masă
  get 't/:slug' => 'bill_sessions#create_session', as: :create_bill_session
  get 'session/:session_token' => 'bill_sessions#show_session', as: :show_bill_session
  post 'validate_qr_token' => 'bill_sessions#validate_qr_token', as: :validate_qr_token
  
  namespace :users do
    #PAYMENTS
    post 'payment/create_payment' => 'payments#create_payment'
    post 'payment/pay_bill' => 'payments#pay_bill'
    
    #ITEM_TABLE_RELATIONS
    get 'item_table_relations' => 'item_table_relations#index'
  end
end
