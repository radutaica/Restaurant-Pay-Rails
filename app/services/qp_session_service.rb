class QpSessionService
  SESSION_PREFIX = "qp_session:"
  SESSION_EXPIRATION = 900 # 15 minutes in seconds

  class << self
    # Creează o sesiune în Redis
    # Returnează session_id
    def create_session(venue_id:, table_id:, bill_id:)
      session_id = SecureRandom.hex(32)
      session_data = {
        venue_id: venue_id,
        table_id: table_id,
        bill_id: bill_id,
        exp: 15.minutes.from_now.to_i
      }
      
      redis_key = "#{SESSION_PREFIX}#{session_id}"
      redis.setex(redis_key, SESSION_EXPIRATION, session_data.to_json)
      
      session_id
    end

    # Citește sesiunea din Redis
    # Returnează hash cu venue_id, table_id, bill_id sau nil dacă nu există
    def get_session(session_id)
      return nil if session_id.blank?
      
      redis_key = "#{SESSION_PREFIX}#{session_id}"
      session_json = redis.get(redis_key)
      
      return nil if session_json.blank?
      
      JSON.parse(session_json).with_indifferent_access
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse session data: #{e.message}"
      nil
    end

    # Șterge sesiunea din Redis
    def delete_session(session_id)
      return false if session_id.blank?
      
      redis_key = "#{SESSION_PREFIX}#{session_id}"
      redis.del(redis_key) > 0
    end

    # Verifică dacă sesiunea există
    def session_exists?(session_id)
      return false if session_id.blank?
      
      redis_key = "#{SESSION_PREFIX}#{session_id}"
      # exists? este disponibil în Redis 4.0+, pentru compatibilitate folosim get
      redis.get(redis_key).present?
    end

    # Șterge toate sesiunile pentru un bill_id dat
    # Util pentru când bill.status devine closed
    def delete_sessions_for_bill(bill_id)
      pattern = "#{SESSION_PREFIX}*"
      deleted_count = 0
      
      redis.scan_each(match: pattern) do |key|
        session_json = redis.get(key)
        next if session_json.blank?
        
        begin
          session_data = JSON.parse(session_json)
          if session_data['bill_id'] == bill_id || session_data[:bill_id] == bill_id
            redis.del(key)
            deleted_count += 1
          end
        rescue JSON::ParserError
          # Skip invalid JSON
        end
      end
      
      deleted_count
    end

    private

    def redis
      @redis ||= Redis.new(url: redis_url)
    end

    def redis_url
      ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" }
    end
  end
end

