module Api
  module V1
    class WebhooksController < ApplicationController
      skip_before_action :authenticate_request, only: [:bank_update]

      # POST /api/v1/webhooks/bank_update
      def bank_update       
        application = CreditApplication.find_by(id: webhook_params[:application_id])
        
        if application.nil?
          render json: { error: "Solicitud no encontrada" }, status: :not_found
          return
        end

        if webhook_params[:status].present? && CreditApplication::VALID_STATUSES.include?(webhook_params[:status])
          application.update(status: webhook_params[:status])
          render json: { message: "Webhook procesado exitosamente" }, status: :ok
        else
          render json: { error: "Payload inválido o estado no permitido" }, status: :unprocessable_entity
        end
      end

      private

      def webhook_params
        params.require(:webhook).permit(:application_id, :status, :event, payload: {})
      end
    end
  end
end
