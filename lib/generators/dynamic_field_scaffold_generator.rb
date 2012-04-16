require 'rails/generators/active_record/migration'
class DynamicFieldScaffoldGenerator < Rails::Generators::Base
  
  include Rails::Generators::Migration
  # extend ActiveRecord::Generators::Migration
  argument :table_name, :type => :string
  argument :arguments, :type => :hash
  
  source_root File.expand_path('../templates', __FILE__)

  def generate_migration
    
    template "fields_table_migration.rb", "db/migrate/#{next_migration_number(Time.now)}_create_#{fields_table_name}.rb"
    template "fieldvalues_table_migration.rb", "db/migrate/#{next_migration_number(Time.now+1)}_create_#{fieldvalues_table_name}.rb"
    
    if use_fieldoptions_table
      template "fieldoptions_table_migration.rb", "db/migrate/#{next_migration_number(Time.now+2)}_create_#{fieldoptions_table_name}.rb"
    end
    
    if create_fieldgroup_table
      template "fieldgroups_table_migration.rb", "db/migrate/#{next_migration_number(Time.now+3)}_create_#{fieldgroup_table_name}.rb"
    end
    
    if create_models
      template "fields_model_template.rb", "app/models/#{fields_model_name.tableize.singularize}.rb"
      template "fieldvalues_model_template.rb", "app/models/#{fieldvalues_model_name.tableize.singularize}.rb"
      if use_fieldoptions_table
        template "fieldoptions_model_template.rb", "app/models/#{fieldoptions_model_name.tableize.singularize}.rb"
      end
      if use_fieldgroup_table
        template "fieldgroup_model_template.rb", "app/models/#{fieldgroup_model_name.tableize.singularize}.rb"
      end
    end

  end
  
  private
  
  def create_models
    if arguments["create_models"].present?
      arguments["create_models"]
    else
      return true
    end  
  end  
  
  def use_fieldgroup_table
    arguments["use_fieldgroup_table"]
  end
  
  def fieldgroup_table_name
    arguments["fieldgroup_table_name"]
  end
  
  def fieldgroup_klass_name
    arguments["fieldgroup_table_name"].singularize.classify
  end  
  
  def create_fieldgroup_table
    if use_fieldgroup_table
      if arguments["create_fieldgroup_table"].present?
        return arguments["create_fieldgroup_table"]
      else
        return true
      end
    else
      return false
    end    
  end
  
  def fieldgroup_foreign_key
    "#{arguments["fieldgroup_table_name"].singularize}_id"
  end
  
  def use_fieldoptions_table
    if arguments["use_fieldoptions_table"].present?
      return arguments["use_fieldoptions_table"]
    else
      return true
    end    
  end
  
  def fieldoptions_table_name
    if arguments["fieldoptions_table_name"].present?
      arguments["fieldoptions_table_name"]
    else
      "#{table_name.underscore}_field_options"
    end
  end
  
  def fieldoptions_klass_name
    fieldoptions_table_name.singularize.classify
  end
  
  def entity_klass_name
    table_name.classify.singularize
  end
  
  def entity_table_name
    entity_klass_name.underscore.pluralize
  end
  
  def entity_foreign_key
    "#{entity_table_name.singularize}_id"
  end  
  
  def fields_table_name
    "#{table_name.underscore}_fields"
  end
  
  def fields_klass_name
    fields_table_name.classify.pluralize
  end
  
  def fieldvalues_table_name
    "#{table_name.underscore}_field_values"    
  end
  
  def fieldvalues_klass_name
    fieldvalues_table_name.classify.singularize
  end
  
  def fields_model_name
    fields_table_name.classify.singularize
  end
  
  def fieldvalues_model_name
    fieldvalues_table_name.classify.singularize
  end
  
  def fieldoptions_model_name
    fieldoptions_table_name.classify.singularize
  end
  
  def fieldgroup_model_name
    fieldgroup_table_name.classify.singularize
  end
      
  def next_migration_number(time)
    # @migration_count ||= 0
    if ActiveRecord::Base.timestamped_migrations
      time.utc.strftime("%Y%m%d%H%M%S")
    else
      "%.3d" % (current_migration_number("db/migrate") + 1)
    end
  end
  
end  