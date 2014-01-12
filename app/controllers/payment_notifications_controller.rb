class PaymentNotificationsController < ApplicationController
  before_filter :login_required, :registration_required, :location_required

  protect_from_forgery :except => [:create]
  
  def create
    PaymentNotification.create!(:params => params, :paypal_transaction_id => params[:invoice], :status => params[:payment_status], :txn_id => params[:txn_id])
    render :nothing => true
  end
end
