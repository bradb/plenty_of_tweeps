module MessagesHelper

  def inbox_subnav_tab_links
    [
      { :url_path => messages_path,
        :text => "Inbox (#{current_user.all_unread_messages_count})",
        :selected => request.path =~ /inbox/ && request.path !~ /sent/},
      { :url_path => sent_messages_path,
        :text => "Sent Messages (#{current_user.messages_from.count})",
        :selected => request.path =~ /inbox\/sent/ }
    ]
  end
  
  def reply_subject(subject)
    if subject =~ /^Re:/i
      return subject
    else
      return "Re: #{subject}"
    end
  end
  
end
