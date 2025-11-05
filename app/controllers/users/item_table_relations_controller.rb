class Users::ItemTableRelationsController < ApplicationController
  before_action :validate_session_token, only: [:index]

  def index
    table_id = params[:table_id]
    
    if table_id.blank?
      return render json: { error: 'table_id parameter is required' }, status: :bad_request
    end

    # Validate that table_id in params matches the one in session token
    if @session_data[:table_id].to_s != table_id.to_s
      return render json: { error: 'Table ID mismatch with session token' }, status: :unauthorized
    end

    table = Table.find_by(id: table_id)
    if table.nil?
      return render json: { error: 'Table not found' }, status: :not_found
    end

    items = table.items
    render json: items
  end

  def show
    entry = ItemTableRelation.find(params[:id])
    render json: entry
  end

  def create
    entry = ItemTableRelation.create(item_table_relation_params)
    render json: entry
  end

  private

  def validate_session_token
    # Check for X-Session-Token header first (as sent by the client)
    # Rails converts headers, so we check both formats
    session_token = request.headers['X-Session-Token'] || 
                    request.headers['HTTP_X_SESSION_TOKEN'] ||
                    params[:session_token] || 
                    request.headers['Authorization']&.split(' ')&.last
    
    if session_token.blank?
      return render json: { error: 'Session token is required' }, status: :unauthorized
    end
    
    @session_data = decode_session_token(session_token)
    
    if @session_data.nil?
      return render json: { error: 'Invalid session token' }, status: :unauthorized
    end
    
    # Check if token has expired
    if Time.current.to_i > @session_data[:expires_at]
      return render json: { error: 'Session token has expired' }, status: :unauthorized
    end
  end

  def decode_session_token(token)
    decoded_token = JWT.decode(token, Rails.application.secret_key_base, true, { algorithm: 'HS256' })
    decoded_token[0].with_indifferent_access
  rescue JWT::DecodeError => e
    Rails.logger.error "Session token decode error: #{e.message}"
    nil
  rescue JWT::ExpiredSignature => e
    Rails.logger.error "Session token expired: #{e.message}"
    nil
  end

  def item_table_relation_params
    params.require(:item_table_relation).permit(:item_id, :table_id)
  end
end