require 'active_record'

module ValidatesBlanknessOf
  module ClassMethods
    def validates_blankness_of(*attr_names)
      options = { :message => "must be blank" }
      options.update(attr_names.pop) if attr_names.last.is_a?(Hash)
      validates_each attr_names, options do |record, attr_name, value|
        record.errors.add(attr_name, options[:message]) unless record.send(attr_name).blank?
      end
    end
  end
  
  def self.included(receiver)
    receiver.extend ClassMethods
  end
end

ActiveRecord::Base.send(:include, ValidatesBlanknessOf)