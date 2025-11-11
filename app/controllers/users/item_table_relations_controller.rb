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
    if !load_session_from_redis
      return render json: { error: 'Invalid or expired session' }, status: :unauthorized
    end
  end

  def item_table_relation_params
    params.require(:item_table_relation).permit(:item_id, :table_id)
  end
end