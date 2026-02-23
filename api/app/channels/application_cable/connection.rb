module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      token = request.params[:token] || request.headers["Authorization"]&.split(" ")&.last
      if token
        decoded = JwtService.decode(token)
        User.find(decoded[:user_id])
      else
        reject_unauthorized_connection
      end
    rescue => e
      Rails.logger.warn("ActionCable connection rejected: #{e.message}")
      reject_unauthorized_connection
    end
  end
end
