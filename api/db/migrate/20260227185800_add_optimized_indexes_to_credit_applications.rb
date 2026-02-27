class AddOptimizedIndexesToCreditApplications < ActiveRecord::Migration[8.1]
  def change
    # 1. Índice compuesto para optimizar búsquedas recientes por estado
    add_index :credit_applications, [:status, :created_at], order: { created_at: :desc }, name: 'idx_credit_apps_status_created_at'

    # 2. Índice único parcial para evitar múltiples solicitudes pendientes
    add_index :credit_applications, [:country, :identity_document], unique: true, where: "status = 'pending'", name: 'idx_unique_pending_credit_apps'
  end
end
