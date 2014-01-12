require 'active_record'

module ValidatesCreationCount
  class << self
    module ClassMethods
      def validates_creation_count(options = {})
        options.assert_valid_keys(:maximum, :time_frame, :message, :scope, :if)
        validate_on_create options.slice(:if) do |message|
          time_frame = options[:time_frame]
          if time_frame
            time_frame_in_hours = time_frame / 1.hour
          end
          scope = options[:scope]
          maximum = options[:maximum]
          if options[:message]
            error_message = options[:message]
          else
            if time_frame_in_hours
              error_message = "#{self.class_name.downcase} create limit exceeded (maximum #{maximum} every #{time_frame_in_hours} hour#{time_frame_in_hours > 1 ? 's' : ''})"
            else
              error_message = "#{self.class_name.downcase} create limit exceeded (maximum #{maximum})"
            end
          end

          condition_fragments = []
          condition_fragments << ["created_at >= ?", time_frame.ago] if time_frame
          if scope && message.respond_to?(scope)
            condition_fragments << ["#{scope} = ?", message.send(scope)]
          end

          most_recent_items_count = count :conditions => [
            condition_fragments.map { |frag| frag[0] }.join(" AND "),
            *condition_fragments.map { |frag| frag[1] }]

          unless most_recent_items_count < maximum
            message.errors.add_to_base(error_message)
          end
        end
      end
    end
    
    def included(base_class)
      base_class.extend(ClassMethods)
    end
  end
end

ActiveRecord::Base.send(:include, ValidatesCreationCount)