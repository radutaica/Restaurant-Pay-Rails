class QrGeneratorService
  include Rails.application.routes.url_helpers
  
  def initialize(table_or_params)
    if table_or_params.is_a?(Table)
      @table = table_or_params
      @venue = @table.venue
    elsif table_or_params.is_a?(Hash)
      # Acceptă hash cu venue_id și table_id
      @venue_id = table_or_params[:venue_id] || table_or_params['venue_id']
      @table_id = table_or_params[:table_id] || table_or_params['table_id']
      
      @venue = Venue.find(@venue_id)
      @table = @venue.tables.find(@table_id)
    else
      raise ArgumentError, "Expected Table object or hash with venue_id and table_id"
    end
  end
  
  def generate_qr_url
    # Generăm un token sigur care conține table_id și venue_id într-un singur identificator
    token_data = {
      table_id: @table.id,
      venue_id: @venue.id,
      slug: @venue.slug,
      iat: Time.current.to_i # issued at timestamp pentru validare
    }
    
    # Encodăm tokenul ca JWT pentru siguranță
    token = JWT.encode(token_data, Rails.application.secret_key_base, 'HS256')
    
    # Generăm URL-ul pentru QR code - conține ambele ID-uri în token
    "#{base_url}/t/#{@venue.slug}?t=#{token}"
  end
  
  def generate_qr_code(size: 300)
    require 'rqrcode'
    
    qr_url = generate_qr_url
    qr = RQRCode::QRCode.new(qr_url)
    
    # Generăm QR code ca SVG pentru scalabilitate
    qr.as_svg(
      offset: 0,
      color: '000',
      shape_rendering: 'crispEdges',
      module_size: 6,
      standalone: true,
      use_path: true
    )
  end
  
  def generate_qr_png(size: 300)
    require 'rqrcode'
    require 'chunky_png'
    
    qr_url = generate_qr_url
    qr = RQRCode::QRCode.new(qr_url)
    
    # Generăm QR code ca PNG
    qr.as_png(
      bit_depth: 1,
      border_modules: 4,
      color_mode: ChunkyPNG::COLOR_GRAYSCALE,
      color: 'black',
      file: nil,
      fill: 'white',
      module_px_size: 6,
      resize_exactly_to: false,
      resize_gte_to: false,
      size: size
    )
  end
  
  private
  
  def base_url
    # În producție, folosește domeniul real
    if Rails.env.production?
      'https://m.plateste.app'
    else
      'https://944e767af31d.ngrok-free.app'
    end
  end
  
  # Metodă pentru decodarea tokenului (pentru verificare)
  def self.decode_token(token)
    decoded_token = JWT.decode(token, Rails.application.secret_key_base, true, { algorithm: 'HS256' })
    decoded_token[0] # Returnează payload-ul
  rescue JWT::DecodeError => e
    Rails.logger.error "JWT decode error: #{e.message}"
    nil
  end
  
  # Metodă pentru validarea și extragerea datelor din token
  def self.extract_table_and_venue(token)
    payload = decode_token(token)
    return nil unless payload
    
    {
      table_id: payload['table_id'],
      venue_id: payload['venue_id'],
      venue_slug: payload['slug'],
      issued_at: payload['iat']
    }
  end
  
  # Metode helper pentru apelarea directă din consolă
  def self.generate_for_table(venue_id:, table_id:, size: 300)
    service = new({ venue_id: venue_id, table_id: table_id })
    
    {
      venue_id: venue_id,
      table_id: table_id,
      venue_name: service.instance_variable_get(:@venue).name,
      table_name: service.instance_variable_get(:@table).name,
      qr_url: service.generate_qr_url,
      qr_svg: service.generate_qr_code(size: size),
      qr_png: service.generate_qr_png(size: size)
    }
  end
  
  def self.generate_url_for_table(venue_id:, table_id:)
    service = new({ venue_id: venue_id, table_id: table_id })
    service.generate_qr_url
  end
  
  def self.generate_svg_for_table(venue_id:, table_id:, size: 300)
    service = new({ venue_id: venue_id, table_id: table_id })
    service.generate_qr_code(size: size)
  end
  
  def self.generate_png_for_table(venue_id:, table_id:, size: 300)
    service = new({ venue_id: venue_id, table_id: table_id })
    service.generate_qr_png(size: size)
  end
end
