class MessagesController < ApplicationController

  before_filter :login_required, :registration_required, :location_required, :set_recently_online_users

  def show
    @message = current_user.visible_messages_to.find_by_id(params[:id])
    unless @message.present?
      @message = current_user.messages_from.find_by_id(params[:id])
    end
    
    if @message.present?
      @message.mark_read! if current_user == @message.to_user && @message.unread?
      return
    else
      render :nothing => true, :status => 404
    end
  end
  
  def send_msg_to
    to_user = User.find_by_login(params[:login])
    unless to_user.present?
      twitter_auth_user_hash = current_user.get_twitter_user(params[:login])
      to_user = User.new_from_twitter_auth_user_hash(twitter_auth_user_hash)
      to_user.save!
      to_user.reload
    end
    
    if request.get?
      @message = current_user.build_message_to(to_user, params[:message])
    elsif request.post?      
      @message = current_user.send_message_to_and_notify(to_user, params[:message])
      if @message.valid?
        flash[:notice] = "Message sent to #{CGI.escapeHTML @message.to_user.login}."
        redirect_to messages_url
      else
        return
      end
    end
  end

end
