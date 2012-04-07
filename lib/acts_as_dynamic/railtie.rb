require "acts_as_dynamic"
require "rails"

module ActsAsDynamic
  class Railtie < Rails::Railtie
    initializer 'acts_as_dynamic.ar_extensions' do |app|
      require 'acts_as_dynamic/has_dynamic_fields' if defined?(Rails)

      ActiveRecord::Base.extend ActsAsDynamic::Base
      ActiveRecord::Base.send :extend, ActsAsDynamic::HasDynamicFields
 
    end
    
    generators do
      require "generators/dynamic_field_migration_generator"
    end
    
    rake_tasks do
      load "tasks/dynamic_field_migrate.rake"
    end
    
  end
end