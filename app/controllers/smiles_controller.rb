class SmilesController < ApplicationController
  before_filter :login_required, :registration_required, :location_required, :set_recently_online_users
  
  def destroy
    current_user.smiles_received.find_by_id(params[:id]).seen!
    render :nothing => true
  end

end
