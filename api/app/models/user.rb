class User < ApplicationRecord
  has_secure_password
  has_many :credit_applications, dependent: :nullify

  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, allow_blank: true

  before_save :downcase_email

  def auth_token
    JwtService.encode(user_id: id, email: email)
  end

  private

  def downcase_email
    self.email = email.downcase
  end
end
