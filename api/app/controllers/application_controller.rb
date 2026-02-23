class ApplicationController < ActionController::API
  include ExceptionHandler
  include Pagy::Backend

  before_action :authenticate_request

  rescue_from ExceptionHandler::AuthenticationError, with: :unauthorized
  rescue_from ExceptionHandler::MissingToken, with: :unauthorized
  rescue_from ExceptionHandler::InvalidToken, with: :unauthorized
  rescue_from ExceptionHandler::ExpiredSignature, with: :unauthorized
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity

  private

  def authenticate_request
    @current_user = AuthorizeApiRequest.call(request.headers).result
    render json: { error: "Not Authorized" }, status: :unauthorized unless @current_user
  end

  def unauthorized(error)
    render json: { error: error.message }, status: :unauthorized
  end

  def not_found(error)
    render json: { error: error.message }, status: :not_found
  end

  def unprocessable_entity(error)
    render json: { error: error.record.errors.full_messages }, status: :unprocessable_entity
  end
end
