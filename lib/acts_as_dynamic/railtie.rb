require "acts_as_dynamic"
require "rails"

module ActsAsDynamic
  class Railtie < Rails::Railtie
    initializer 'acts_as_dynamic.ar_extensions' do |app|
      require 'acts_as_dynamic/has_dynamic_field_values' if defined?(Rails)

      ActiveRecord::Base.extend ActsAsDynamic::Base
      ActiveRecord::Base.send :extend, ActsAsDynamic::HasDynamicFieldValues
 
    end
  end
end