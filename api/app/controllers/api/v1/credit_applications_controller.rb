module Api
  module V1
    class CreditApplicationsController < ApplicationController
      before_action :set_application, only: [ :show ]

      # GET /api/v1/credit_applications
      def index
        applications_query = CreditApplication
          .by_country(params[:country])
          .by_status(params[:status])
          .recent

        @pagy, applications = pagy(
          applications_query, 
          page: params[:page] || 1, 
          limit: params[:per_page] || 20
        )

        render json: {
          data: applications.map { |a| application_json(a) },
          meta: {
            total: @pagy.count,
            page: @pagy.page,
            per_page: @pagy.limit,
            pages: @pagy.pages
          }
        }
      end

      # GET /api/v1/credit_applications/:id
      def show
        render json: { data: application_json(@application, include_audit: true) }
      end

      # POST /api/v1/credit_applications
      def create
        application = CreditApplication.new(application_params)
        application.user = @current_user

        if application.save
          render json: {
            message: "Solicitud de crédito creada. Evaluación en proceso.",
            data: application_json(application)
          }, status: :created
        else
          render json: { error: application.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/credit_applications/:id/status
      def update_status
        application = CreditApplication.find(params[:id])
        new_status = params[:status]

        unless CreditApplication::VALID_STATUSES.include?(new_status)
          render json: { error: "Estado inválido: #{new_status}" }, status: :unprocessable_entity
          return
        end

        if application.update(status: new_status)
          render json: { data: application_json(application), message: "Estado actualizado correctamente" }
        else
          render json: { error: application.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/credit_applications/countries
      def countries
        render json: { data: Countries::StrategyFactory.supported_countries }
      end

      # GET /api/v1/credit_applications/statuses
      def statuses
        translated_statuses = CreditApplication::VALID_STATUSES.map do |s|
          { code: s, name: I18n.t("credit_applications.statuses.#{s}") }
        end
        render json: { data: translated_statuses }
      end

      private

      def set_application
        @application = CreditApplication.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Solicitud no encontrada" }, status: :not_found
      end

      def application_params
        params.require(:credit_application).permit(
          :country, :full_name, :identity_document,
          :requested_amount, :monthly_income, :application_date
        )
      end

      def application_json(app, include_audit: false)
        result = {
          id: app.id,
          country: app.country,
          country_name: Countries::StrategyFactory::COUNTRY_NAMES[app.country] || app.country,
          full_name: app.full_name,
          identity_document: app.identity_document,
          requested_amount: app.requested_amount,
          monthly_income: app.monthly_income,
          application_date: app.application_date,
          status: app.status,
          status_name: I18n.t("credit_applications.statuses.#{app.status}"),
          banking_information: app.banking_information,
          created_at: app.created_at,
          updated_at: app.updated_at
        }
        result[:audit_logs] = app.audit_logs.recent.map { |l| {
          old_status: l.old_status,
          old_status_name: l.old_status ? I18n.t("credit_applications.statuses.#{l.old_status}") : nil,
          new_status: l.new_status,
          new_status_name: I18n.t("credit_applications.statuses.#{l.new_status}"),
          changed_at: l.created_at
        }} if include_audit
        result
      end
    end
  end
end
