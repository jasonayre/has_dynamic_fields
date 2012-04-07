require 'rails/generators/active_record/migration'
class DynamicFieldScaffoldGenerator < Rails::Generators::Base
  
  include Rails::Generators::Migration
  # extend ActiveRecord::Generators::Migration
  argument :migration_name, :type => :string
  argument :arguments, :type => :hash
  
  source_root File.expand_path('../templates', __FILE__)

  def generate_migration
    
    template "#{migration_type}_field_migration.rb", "db/migrate/dynamic_fields/#{next_migration_number}_#{file_name}.rb"

    # puts args.inspect
    # ActiveRecord::Migration.next_migration_number(self.next_migration_number)
  end
  
  private
  
  def file_name
    migration_name.underscore
  end
  
end  