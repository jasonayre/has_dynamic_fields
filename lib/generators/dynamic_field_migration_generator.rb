require 'rails/generators/active_record/migration'
class DynamicFieldMigrationGenerator < Rails::Generators::Base
  
  include Rails::Generators::Migration
  # extend ActiveRecord::Generators::Migration
  argument :migration_name, :type => :string
  argument :arguments, :type => :hash
  
  source_root File.expand_path('../templates', __FILE__)

  def generate_migration
    
    template "#{migration_type}_field_migration.rb", "db/migrate/dynamic_fields/#{next_migration_number}_#{file_name}.rb"
    puts "HI I AM WORKING"
    # puts args.inspect
    # ActiveRecord::Migration.next_migration_number(self.next_migration_number)
  end
  
  private
  
  def file_name
    migration_name.underscore
  end
  
  def migration_type
    file_name.split("_").first
  end
  
  def migration_verb
    if migration_type == "add"
      return "to"
    elsif migration_type == "remove"
      return "from"
    end    
  end
  
  def table_name
    migration_name.sub("#{migration_type}_", "").split("_#{migration_verb}_").last
  end
  
  def field_id
    migration_name.sub("#{migration_type}_field_", "").split("_#{migration_verb}_").first
  end
  
  def column_name
    migration_name.sub("#{migration_type}_", "").split("_#{migration_verb}_").first
  end
  
  def column_type
    arguments[column_name].to_sym
  end
  
  def migration_klass_name
    file_name.classify.pluralize
  end
  
  def next_migration_number
    if ActiveRecord::Base.timestamped_migrations
      Time.now.utc.strftime("%Y%m%d%H%M%S")
    else
      "%.3d" % (current_migration_number("db/migrate") + 1)
    end
    
  end
  
  def data_table_name
    table_name.sub("_data", "")
  end
  
  def field_entity
    data_table_name.classify.constantize.find(field_id)
  end  
  
end
