# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Starting database seeding..."

# Clear existing data
puts "🧹 Clearing existing data..."
ItemTableRelation.destroy_all
Item.destroy_all
Table.destroy_all
Venue.destroy_all

# Create Venue
puts "🏢 Creating venue..."
venue = Venue.create!(
  name: "Restaurant Românesc",
  slug: "restaurant-romanesc"
)
puts "✅ Created venue: #{venue.name}"

# Create Tables
puts "🪑 Creating tables..."
tables = [
  { name: "Masa 1", venue: venue },
  { name: "Masa 2 - Centru", venue: venue },
  { name: "Masa 3 - Colț", venue: venue },
  { name: "Masa 4 - Terasă", venue: venue },
  { name: "Masa 5 - VIP", venue: venue },
  { name: "Masa 6 - Balcon", venue: venue },
  { name: "Masa 7 - Intimă", venue: venue },
  { name: "Masa 8 - Grup mare", venue: venue },
  { name: "Masa 9 - Bar", venue: venue },
  { name: "Masa 10 - Privată", venue: venue }
]

created_tables = tables.map { |table_data| Table.create!(table_data) }
puts "✅ Created #{created_tables.count} tables"

# Create Items (Romanian restaurant menu)
puts "🍽️ Creating menu items..."
items = [
  # Aperitive
  { name: "Bruschete cu roșii și busuioc", price_cents: 2500, venue: venue },
  { name: "Platou de brânzeturi românești", price_cents: 3500, venue: venue },
  { name: "Salată de vinete", price_cents: 1800, venue: venue },
  { name: "Zacuscă de legume", price_cents: 2200, venue: venue },
  { name: "Pâine cu usturoi", price_cents: 1200, venue: venue },
  
  # Supe și ciorbe
  { name: "Ciorbă de burtă", price_cents: 2800, venue: venue },
  { name: "Ciorbă țărănească", price_cents: 2400, venue: venue },
  { name: "Supă de pui cu tăiței", price_cents: 2000, venue: venue },
  { name: "Ciorbă de legume", price_cents: 1800, venue: venue },
  
  # Feluri principale - Carne
  { name: "Mici cu muștar și pâine", price_cents: 3200, venue: venue },
  { name: "Sarmale cu smântână", price_cents: 3500, venue: venue },
  { name: "Tochitură moldovenească", price_cents: 4200, venue: venue },
  { name: "Papanași cu smântână și dulceață", price_cents: 2800, venue: venue },
  { name: "Cozonac cu nucă", price_cents: 1500, venue: venue },
  { name: "Frigarui de porc", price_cents: 3800, venue: venue },
  { name: "Musaca de cartofi", price_cents: 3000, venue: venue },
  { name: "Ghiveci de legume", price_cents: 2600, venue: venue },
  
  # Feluri principale - Pește
  { name: "Pește la grătar cu legume", price_cents: 4500, venue: venue },
  { name: "Crap la cuptor cu usturoi", price_cents: 4000, venue: venue },
  { name: "Saramură de pește", price_cents: 3800, venue: venue },
  
  # Garnituri
  { name: "Cartofi prăjiți", price_cents: 1500, venue: venue },
  { name: "Cartofi la cuptor", price_cents: 1800, venue: venue },
  { name: "Orez cu legume", price_cents: 1200, venue: venue },
  { name: "Salată de varză", price_cents: 1000, venue: venue },
  { name: "Salată de roșii și castraveți", price_cents: 1400, venue: venue },
  
  # Deserturi
  { name: "Clătite cu dulceață", price_cents: 2000, venue: venue },
  { name: "Plăcintă cu brânză", price_cents: 1800, venue: venue },
  { name: "Gogoașe cu gem", price_cents: 1200, venue: venue },
  { name: "Tort de ciocolată", price_cents: 2500, venue: venue },
  { name: "Înghețată cu fructe", price_cents: 1600, venue: venue },
  
  # Băuturi
  { name: "Coca-Cola", price_cents: 800, venue: venue },
  { name: "Fanta", price_cents: 800, venue: venue },
  { name: "Sprite", price_cents: 800, venue: venue },
  { name: "Apă minerală", price_cents: 500, venue: venue },
  { name: "Suc de portocale", price_cents: 1200, venue: venue },
  { name: "Suc de mere", price_cents: 1200, venue: venue },
  { name: "Cafea", price_cents: 600, venue: venue },
  { name: "Ceai de mușețel", price_cents: 500, venue: venue },
  { name: "Limonadă", price_cents: 1000, venue: venue },
  { name: "Bere Ursus", price_cents: 1500, venue: venue },
  { name: "Vin roșu de casă", price_cents: 2500, venue: venue },
  { name: "Vin alb de casă", price_cents: 2500, venue: venue },
  { name: "Țuică", price_cents: 2000, venue: venue }
]

created_items = items.map { |item_data| Item.create!(item_data) }
puts "✅ Created #{created_items.count} menu items"

# Create Item-Table Relations (simulating orders)
puts "🔗 Creating item-table relations (simulating orders)..."

# Define some realistic order scenarios
orders = [
  # Masa 1 - Order for 2 people
  { table: created_tables[0], items: [
    { item: created_items.find { |i| i.name.include?("Bruschete") }, quantity: 1 },
    { item: created_items.find { |i| i.name.include?("Ciorbă de burtă") }, quantity: 2 },
    { item: created_items.find { |i| i.name.include?("Mici") }, quantity: 1 },
    { item: created_items.find { |i| i.name.include?("Coca-Cola") }, quantity: 2 },
    { item: created_items.find { |i| i.name.include?("Cafea") }, quantity: 2 }
  ]},
  
  # Masa 2 - Family order
  { table: created_tables[1], items: [
    { item: created_items.find { |i| i.name.include?("Platou de brânzeturi") }, quantity: 1 },
    { item: created_items.find { |i| i.name.include?("Sarmale") }, quantity: 2 },
    { item: created_items.find { |i| i.name.include?("Tochitură") }, quantity: 1 },
    { item: created_items.find { |i| i.name.include?("Cartofi prăjiți") }, quantity: 2 },
    { item: created_items.find { |i| i.name.include?("Salată de roșii") }, quantity: 1 },
    { item: created_items.find { |i| i.name.include?("Apă minerală") }, quantity: 4 },
    { item: created_items.find { |i| i.name.include?("Clătite") }, quantity: 2 }
  ]},
  
  # Masa 3 - Business lunch
  { table: created_tables[2], items: [
    { item: created_items.find { |i| i.name.include?("Salată de vinete") }, quantity: 1 },
    { item: created_items.find { |i| i.name.include?("Supă de pui") }, quantity: 1 },
    { item: created_items.find { |i| i.name.include?("Frigarui") }, quantity: 1 },
    { item: created_items.find { |i| i.name.include?("Orez cu legume") }, quantity: 1 },
    { item: created_items.find { |i| i.name.include?("Cafea") }, quantity: 1 }
  ]},
  
  # Masa 4 - Romantic dinner
  { table: created_tables[3], items: [
    { item: created_items.find { |i| i.name.include?("Zacuscă") }, quantity: 1 },
    { item: created_items.find { |i| i.name.include?("Pește la grătar") }, quantity: 2 },
    { item: created_items.find { |i| i.name.include?("Cartofi la cuptor") }, quantity: 1 },
    { item: created_items.find { |i| i.name.include?("Salată de roșii") }, quantity: 1 },
    { item: created_items.find { |i| i.name.include?("Vin roșu") }, quantity: 1 },
    { item: created_items.find { |i| i.name.include?("Tort de ciocolată") }, quantity: 1 }
  ]},
  
  # Masa 5 - VIP table
  { table: created_tables[4], items: [
    { item: created_items.find { |i| i.name.include?("Platou de brânzeturi") }, quantity: 1 },
    { item: created_items.find { |i| i.name.include?("Ciorbă țărănească") }, quantity: 2 },
    { item: created_items.find { |i| i.name.include?("Musaca") }, quantity: 1 },
    { item: created_items.find { |i| i.name.include?("Ghiveci") }, quantity: 1 },
    { item: created_items.find { |i| i.name.include?("Papanași") }, quantity: 2 },
    { item: created_items.find { |i| i.name.include?("Vin alb") }, quantity: 1 },
    { item: created_items.find { |i| i.name.include?("Țuică") }, quantity: 2 }
  ]},
  
  # Masa 6 - Group of friends
  { table: created_tables[5], items: [
    { item: created_items.find { |i| i.name.include?("Bruschete") }, quantity: 2 },
    { item: created_items.find { |i| i.name.include?("Ciorbă de legume") }, quantity: 3 },
    { item: created_items.find { |i| i.name.include?("Mici") }, quantity: 2 },
    { item: created_items.find { |i| i.name.include?("Sarmale") }, quantity: 1 },
    { item: created_items.find { |i| i.name.include?("Cartofi prăjiți") }, quantity: 3 },
    { item: created_items.find { |i| i.name.include?("Bere Ursus") }, quantity: 4 },
    { item: created_items.find { |i| i.name.include?("Plăcintă") }, quantity: 2 }
  ]},
  
  # Masa 7 - Quick lunch
  { table: created_tables[6], items: [
    { item: created_items.find { |i| i.name.include?("Ciorbă de burtă") }, quantity: 1 },
    { item: created_items.find { |i| i.name.include?("Mici") }, quantity: 1 },
    { item: created_items.find { |i| i.name.include?("Apă minerală") }, quantity: 1 },
    { item: created_items.find { |i| i.name.include?("Cafea") }, quantity: 1 }
  ]},
  
  # Masa 8 - Large group
  { table: created_tables[7], items: [
    { item: created_items.find { |i| i.name.include?("Platou de brânzeturi") }, quantity: 2 },
    { item: created_items.find { |i| i.name.include?("Zacuscă") }, quantity: 2 },
    { item: created_items.find { |i| i.name.include?("Ciorbă țărănească") }, quantity: 4 },
    { item: created_items.find { |i| i.name.include?("Tochitură") }, quantity: 2 },
    { item: created_items.find { |i| i.name.include?("Sarmale") }, quantity: 3 },
    { item: created_items.find { |i| i.name.include?("Cartofi prăjiți") }, quantity: 4 },
    { item: created_items.find { |i| i.name.include?("Salată de roșii") }, quantity: 2 },
    { item: created_items.find { |i| i.name.include?("Apă minerală") }, quantity: 6 },
    { item: created_items.find { |i| i.name.include?("Bere Ursus") }, quantity: 4 },
    { item: created_items.find { |i| i.name.include?("Clătite") }, quantity: 3 }
  ]},
  
  # Masa 9 - Bar snacks
  { table: created_tables[8], items: [
    { item: created_items.find { |i| i.name.include?("Pâine cu usturoi") }, quantity: 2 },
    { item: created_items.find { |i| i.name.include?("Salată de vinete") }, quantity: 1 },
    { item: created_items.find { |i| i.name.include?("Bere Ursus") }, quantity: 3 },
    { item: created_items.find { |i| i.name.include?("Țuică") }, quantity: 2 }
  ]},
  
  # Masa 10 - Private dining
  { table: created_tables[9], items: [
    { item: created_items.find { |i| i.name.include?("Bruschete") }, quantity: 1 },
    { item: created_items.find { |i| i.name.include?("Platou de brânzeturi") }, quantity: 1 },
    { item: created_items.find { |i| i.name.include?("Ciorbă de burtă") }, quantity: 2 },
    { item: created_items.find { |i| i.name.include?("Pește la grătar") }, quantity: 2 },
    { item: created_items.find { |i| i.name.include?("Crap la cuptor") }, quantity: 1 },
    { item: created_items.find { |i| i.name.include?("Cartofi la cuptor") }, quantity: 2 },
    { item: created_items.find { |i| i.name.include?("Salată de roșii") }, quantity: 1 },
    { item: created_items.find { |i| i.name.include?("Vin roșu") }, quantity: 2 },
    { item: created_items.find { |i| i.name.include?("Vin alb") }, quantity: 1 },
    { item: created_items.find { |i| i.name.include?("Tort de ciocolată") }, quantity: 1 },
    { item: created_items.find { |i| i.name.include?("Înghețată") }, quantity: 2 }
  ]}
]

# Create the item-table relations
total_relations = 0
orders.each do |order|
  order[:items].each do |item_order|
    ItemTableRelation.create!(
      table_id: order[:table].id,
      item_id: item_order[:item].id
    )
    total_relations += 1
  end
end

puts "✅ Created #{total_relations} item-table relations"

puts "🎉 Database seeding completed successfully!"
puts "📊 Summary:"
puts "   - #{created_tables.count} tables created"
puts "   - #{created_items.count} menu items created"
puts "   - #{total_relations} item-table relations created"
puts ""
puts "🚀 You can now test your application with Romanian restaurant data!"
