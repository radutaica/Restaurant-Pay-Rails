# config/initializers/cors.rb

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  # Default CORS for all endpoints
  allow do
    # Allow all ngrok domains and localhost for development
    origins /https?:\/\/.*\.ngrok-free\.app/,
            /https?:\/\/.*\.ngrok\.io/,
            /https?:\/\/.*\.ngrok\.app/,
            'http://localhost:3000',
            'http://localhost:3001',
            'https://localhost:3000',
            'https://localhost:3001'

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true  # Allow credentials for cookies/authentication
  end
end
