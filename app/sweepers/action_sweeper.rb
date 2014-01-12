#class ActionSweeper < ActionController::Caching::Sweeper
#  observe Action

#  def after_create(action)
#    ActionController::Base.new.expire_fragment(/recent-actions-p\d+/)
#  end

#end