class RenameTableTransactionsToPaypalTransactions < ActiveRecord::Migration
  def self.up
    rename_table :transactions, :paypal_transactions
  end

  def self.down
    rename_table :paypal_transactions, :transactions
  end

end
