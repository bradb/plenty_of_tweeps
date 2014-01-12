class PaymentNotification < ActiveRecord::Base
  belongs_to :paypal_transaction
  serialize :params
  after_create :upgrade_paid_user
  
  private
  
  def upgrade_paid_user
    if status == "Completed"
      #Update the transaction record.
      self.paypal_transaction.purchased_at = Time.now
      self.paypal_transaction.save!
      #User is buying 7 more days or 1 more month depending on the item_number.
      if params[:item_number] == 1
        if self.paypal_transaction.user.paid_until.blank?
          self.paypal_transaction.user.paid_until = Time.now+7.days
        else
          self.paypal_transaction.user.paid_until = self.paypal_transaction.user.paid_until+7.days
        end
      else
        if self.paypal_transaction.user.paid_until.blank?
          self.paypal_transaction.user.paid_until = Time.now()+7.month
        else
          self.paypal_transaction.user.paid_until = self.paypal_transaction.user.paid_until+1.month
        end
      end
      #self.paypal_transactions.user.save!
    end
  end
  
end
