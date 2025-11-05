class Users::ItemTableRelationsController < ApplicationController
  def index
    table_id = params[:table_id]
    
    if table_id.blank?
      return render json: { error: 'table_id parameter is required' }, status: :bad_request
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
  def item_table_relation_params
    params.require(:item_table_relation).permit(:item_id, :table_id)
  end
end