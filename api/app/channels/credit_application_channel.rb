class CreditApplicationChannel < ActionCable::Channel::Base
  def subscribed
    stream_from "credit_applications"
    Rails.logger.info("CreditApplicationChannel: Client subscribed")
  end

  def unsubscribed
    Rails.logger.info("CreditApplicationChannel: Client unsubscribed")
  end
end
