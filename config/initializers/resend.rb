Resend.api_key = ENV.fetch('RESEND_API_KEY', nil)
Rails.logger.warn('RESEND_API_KEY is not set') if Resend.api_key.blank?
