module InLast24HoursExtension
  def in_last_24_hours
    find(:all, :conditions => ["#{proxy_reflection.klass.table_name}.created_at >= ?", 24.hours.ago])
  end
end