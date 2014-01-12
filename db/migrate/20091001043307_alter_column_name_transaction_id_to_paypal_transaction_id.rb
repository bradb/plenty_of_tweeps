class AlterColumnNameTransactionIdToPaypalTransactionId < ActiveRecord::Migration
  def self.up
    rename_column :payment_notifications, :transaction_id, :paypal_transaction_id 
  end

  def self.down
    rename_column :payment_notifications, :paypal_transaction_id, :transaction_id 
  end
end
