require "has_dynamic_fields"
require "rails"

module HasDynamicFields
  class Railtie < Rails::Railtie
    initializer 'has_dynamic_fields.ar_extensions' do |app|
      require 'has_dynamic_fields/has_dynamic_fields' if defined?(Rails)
      # ActiveRecord::Base.extend HasDynamicFields::Base
      ActiveRecord::Base.send :extend, HasDynamicFields::Base
    end
    
    generators do
      require "generators/dynamic_field_migration_generator"
    end
    
    rake_tasks do
      load "tasks/dynamic_field_migrate.rake"
    end
    
  end
end