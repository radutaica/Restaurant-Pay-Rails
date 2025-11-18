class AddIdFields < ActiveRecord::Migration[7.0]
  def change
    # Add columns as nullable first
    add_column :tables, :venue_id, :bigint, null: true
    add_column :bills, :venue_id, :bigint, null: true
    add_column :items, :venue_id, :bigint, null: true
    
    # Create a default venue for existing data
    execute <<-SQL
      INSERT INTO venues (name, slug, currency, created_at, updated_at)
      VALUES ('Default Venue', 'default', 'ron', NOW(), NOW())
      ON CONFLICT (slug) DO NOTHING;
    SQL
    
    # Update existing records to reference the default venue
    execute <<-SQL
      UPDATE tables SET venue_id = (SELECT id FROM venues WHERE slug = 'default') WHERE venue_id IS NULL;
      UPDATE bills SET venue_id = (SELECT id FROM venues WHERE slug = 'default') WHERE venue_id IS NULL;
      UPDATE items SET venue_id = (SELECT id FROM venues WHERE slug = 'default') WHERE venue_id IS NULL;
    SQL
    
    # Now make the columns NOT NULL
    change_column_null :tables, :venue_id, false
    change_column_null :bills, :venue_id, false
    change_column_null :items, :venue_id, false
    
    # Add foreign key constraints
    add_foreign_key :tables, :venues
    add_foreign_key :bills, :venues
    add_foreign_key :items, :venues
  end
end
