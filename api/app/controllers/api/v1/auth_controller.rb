module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authenticate_request, only: [ :login, :register ]

      # POST /api/v1/auth/register
      def register
        user = User.new(user_params)
        if user.save
          render json: {
            message: "User created successfully",
            auth_token: user.auth_token,
            user: { id: user.id, email: user.email }
          }, status: :created
        else
          render json: { error: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/auth/login
      def login
        user = User.find_by(email: params[:email]&.downcase)
        if user&.authenticate(params[:password])
          render json: {
            auth_token: user.auth_token,
            user: { id: user.id, email: user.email }
          }, status: :ok
        else
          render json: { error: "Invalid credentials" }, status: :unauthorized
        end
      end

      # GET /api/v1/auth/me
      def me
        render json: { user: { id: @current_user.id, email: @current_user.email } }
      end

      private

      def user_params
        params.permit(:email, :password, :password_confirmation)
      end
    end
  end
end
