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
  resources :webhooks
  namespace :users do
    #PAYMENTS
    post 'payment/create_payment' => 'payments#create_payment'
    post 'payment/pay_bill' => 'payments#pay_bill'
  end
end
