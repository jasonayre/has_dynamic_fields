require "active_record"
module HasDynamicFields

  module Base
    def has_dynamic_fields(options = {})

      options[:entity_class_name] ||= "Entity"
      options[:entity_table_name] ||= options[:entity_class_name].tableize
      options[:entity_foreign_key] ||= "#{options[:entity_class_name].tableize.singularize}_id".to_sym
      options[:entity_singular] ||= options[:entity_class_name].tableize.singularize
      options[:entity_plural] ||= options[:entity_class_name].tableize

      options[:value_class_name] ||= "DynamicFieldValue"
      options[:value_table_name] ||= options[:value_class_name].tableize
      options[:value_foreign_key] ||= options[:value_class_name].tableize.singularize.to_sym
      options[:value_singular] ||= options[:value_class_name].tableize.singularize
      options[:value_plural] ||= options[:value_class_name].tableize

      options[:field_class_name] ||= "DynamicField"
      options[:field_table_name] ||= options[:field_class_name].tableize
      options[:field_foreign_key] ||= "#{options[:field_class_name].tableize.singularize}_id".to_sym
      options[:field_singular] ||= options[:field_class_name].tableize.singularize      
      options[:field_plural] ||= options[:field_class_name].tableize

      options[:fieldgroup_class_name] ||= "DynamicFieldGroup"
      options[:fieldgroup_table_name] ||= options[:fieldgroup_class_name].tableize
      options[:fieldgroup_foreign_key] ||= "#{options[:fieldgroup_class_name].tableize.singularize}_id".to_sym
      options[:fieldgroup_singular] ||= options[:fieldgroup_class_name].tableize.singularize
      options[:fieldgroup_plural] ||= options[:fieldgroup_class_name].tableize

      options[:fieldoptions_class_name] ||= "DynamicFieldOptions"
      options[:fieldoptions_table_name] ||= options[:fieldoptions_class_name].tableize
      options[:fieldoptions_foreign_key] ||= "#{options[:fieldoptions_class_name].tableize.singularize}_id".to_sym
      options[:fieldoptions_singular] ||= options[:fieldoptions_class_name].tableize.singularize
      options[:fieldoptions_plural] ||= options[:fieldoptions_class_name].tableize      

      options[:entity_klass] = options[:entity_class_name].constantize
      options[:field_klass] = options[:field_class_name].constantize
      options[:value_klass] = options[:value_class_name].constantize
      options[:fieldgroup_klass] = options[:fieldgroup_class_name].constantize
      options[:fieldoptions_klass] = options[:fieldoptions_class_name].constantize


      cattr_accessor :aad_options
      self.aad_options ||= Hash.new

      # Return if already present
      return if self.aad_options.keys.include? options[:entity_class_name]

      self.aad_options = options

      include InstanceMethods

      entity_klass = options[:entity_class_name].constantize
      field_klass = options[:field_class_name].constantize
      value_klass = options[:value_class_name].constantize
      fieldgroup_klass = options[:fieldgroup_class_name].constantize
      fieldoptions_klass = options[:fieldoptions_class_name].constantize

      #eval entity class
      class_eval do

        #this can be confusing, because I chose to use a horizontal scaling eav pattern due to file upload/carrierwave, 
        #this may not make a ton of sense if you look at it out of context and without looking @ your db.
        #entity has one value, but that value row contains all the possible field values, entity type specific field values..
        #are controlled through fieldgroup, each entity has 1 fieldgroup (category,channel,type, whatever), and 1 value row

        has_one options[:value_singular].to_sym
        accepts_nested_attributes_for options[:value_singular].to_sym, :allow_destroy => true
        belongs_to options[:fieldgroup_singular].to_sym

        #because field relationships are not automatically saved, we need to set flag then do it explicitly
        before_update :update_dynamic_fields, :if => :update_dynamic_fields?
        before_create :create_dynamic_field_value

      end

      #eval value class
      value_klass.class_eval do

        if (ActiveRecord::Base.connection.table_exists?(options[:field_table_name]) && ActiveRecord::Base.connection.table_exists?(options[:value_table_name]))

          #mount file fields if carrierwave being used
          if value_klass.send(:respond_to?, :mount_uploader)
            @file_fields = field_klass.where(:fieldtype => "file")
            @file_fields.each do |field|
              mount_uploader "field_#{field.id}".to_sym, "#{value_klass.name}Uploader".constantize
            end            
          end
        end

        belongs_to options[:entity_singular].to_sym
        belongs_to options[:fieldgroup_singular].to_sym

      end

      field_klass.class_eval do

        #note your field model must have at least a column or method called name
        before_create :format_name
        after_create :dynamic_field_add_column_migration
        before_destroy :dynamic_field_remove_column_migration

        has_many options[:fieldoptions_plural].to_sym

        belongs_to options[:fieldgroup_singular].to_sym

        cattr_accessor :aad_options
        self.aad_options = options

        def dynamic_field_add_column_migration

          except ||= %w{created_at updated_at}
          except_column_types = [:decimal, :date, :datetime]
          except << self.class.name.constantize.columns.collect {|k| k.name if except_column_types.include?(k.type) }.reject { |val| val == nil }

          except.flatten!

          `rails g dynamic_field_migration add_field_#{self.id}_to_#{self.aad_options[:value_table_name]} field_#{self.id}:string`
          
          SeedFu::Writer.write("db/fixtures/#{self.aad_options[:field_table_name]}.rb", :class_name => self.aad_options[:field_class_name], :constraints => [:name, self.aad_options[:fieldgroup_foreign_key]]) do |writer|
            self.class.name.constantize.all.each do |f|
              @attrs = f.attributes.reject { |k,v| except.include?(k) }
              writer.add(@attrs)
            end
          end

        end

        def dynamic_field_remove_column_migration

          except ||= %w{created_at updated_at}
          except_column_types = [:decimal, :date, :datetime]
          except << self.class.name.constantize.columns.collect {|k| k.name if except_column_types.include?(k.type) }.reject { |val| val == nil }

          except.flatten!

          `rails g dynamic_field_migration remove_field_#{self.id}_from_#{self.aad_options[:value_table_name]} field_#{self.id}`
          `rake db:migrate_dynamic_fields`
          SeedFu::Writer.write("db/fixtures/#{self.aad_options[:field_table_name]}.rb", :class_name => self.aad_options[:field_class_name], :constraints => [:name, self.aad_options[:fieldgroup_foreign_key]]) do |writer|
            self.class.name.constantize.all.each do |f|
              @attrs = f.attributes.reject { |k,v| except.include?(k) }
              writer.add(@attrs)
            end
          end
        end

        def format_name
          self.name = self.name.split(" ").join("_").downcase
        end

        def write_seed_data
          SeedFu::Writer.write("db/fixtures/#{self.aad_options[:field_table_name]}.rb", :class_name => self.aad_options[:field_class_name], :constraints => [:name, self.aad_options[:fieldgroup_foreign_key]]) do |writer|
            self.class.name.constantize.all.each do |f|
              @attrs = f.attributes.reject { |k,v| except.include?(k) }
              writer.add(@attrs)
            end
          end
        end

      end


      fieldoptions_klass.class_eval do

        belongs_to options[:field_singular].to_sym
        after_update :write_seed_data

        if self.respond_to? :mount_uploader
          mount_uploader :image, "#{options[:fieldoptions_class_name]}Uploader".constantize
        end

        cattr_accessor :aad_options
        self.aad_options = options

        def write_seed_data

          except ||= %w{created_at updated_at}
          except_column_types = [:decimal, :date, :datetime]
          except << self.class.name.constantize.columns.collect {|k| k.name if except_column_types.include?(k.type) }.reject { |val| val == nil }

          except.flatten!

          SeedFu::Writer.write("db/fixtures/#{self.aad_options[:fieldoptions_table_name]}.rb", :class_name => self.aad_options[:fieldoptions_class_name], :constraints => [:value, self.aad_options[:field_foreign_key]]) do |writer|
            self.class.name.constantize.all.each do |f|
              @attrs = f.attributes.reject { |k,v| except.include?(k) }
              writer.add(@attrs)
            end

          end          
        end  

      end
      
      # todo: make fieldgroup optional
      fieldgroup_klass.class_eval do
        has_many options[:field_table_name].to_sym
        has_many options[:value_table_name].to_sym, :through => options[:field_table_name].to_sym, :source => options[:entity_singular].to_sym
      end

    end

    module InstanceMethods

      def show_options
        puts self.class.aad_options.inspect
        puts self.aad_options.inspect
      end  

      def update_dynamic_fields?
        instance_variable_get("@update_dynamic_fields")
      end

      def update_dynamic_fields=(val)
        instance_variable_set("@update_dynamic_fields",val)
      end

      def update_dynamic_fields
        self.send(self.aad_options[:value_singular].to_sym).save
      end

      def create_dynamic_field_value
        #save relationship upon initial creation, so that fieldgroup specific fields can now be entered
        #todo: make the whole fieldgroup optional for simple talbles

        value_model = self.aad_options[:value_klass]        
        value_model = value_model.create!({ self.aad_options[:fieldgroup_singular].to_sym => self.send(self.aad_options[:fieldgroup_singular]) })

        self.send("#{self.aad_options[:value_singular]}=".to_sym, value_model)
      end

      def dynamic_field_keys
        #todo: rename this dynamic_fieldgroup_field_keys for simple tables
        return if self.send(self.aad_options[:fieldgroup_singular].to_sym).blank?
        keys = []
        dynamic_fieldgroup_field_keys = self.send(self.aad_options[:fieldgroup_singular].to_sym).send(self.aad_options[:field_plural].to_sym)
        dynamic_fieldgroup_field_keys.each do |o|
          keys << o.name.to_sym
        end
        keys
      end

      def dynamic_field_inputs
        fields = []
        dynamic_fields = self.send(self.aad_options[:fieldgroup_singular].to_sym).send(self.aad_options[:field_plural].to_sym)
        dynamic_fields.each do |field|
          fields << field
        end
      end

      def method_missing(name, *args)

        return if self.send(self.aad_options[:fieldgroup_singular].to_sym).blank?
        m = name.to_s
        type = :reader
        attribute_name = name.to_s.sub(/=$/) do
          type = :writer
          ""
        end

        fieldgroup_fields = self.send(self.aad_options[:fieldgroup_singular].to_sym).send(self.aad_options[:field_plural].to_sym)
        @dynamic_field_keys ||= instance_variable_set("@dynamic_field_keys", fieldgroup_fields.collect {|o| o.name.to_sym })
        @dynamic_fields ||= instance_variable_set("@dynamic_fields", fieldgroup_fields)

        if @dynamic_field_keys.include?(attribute_name.to_sym)

          field = @dynamic_fields.select { |field| field.name.to_sym == attribute_name.to_sym && field.send(self.aad_options[:fieldgroup_singular]).id == self.send(self.aad_options[:fieldgroup_singular]).id }.first

          case(type)

          when :writer
            self.update_dynamic_attributes=(true)
            self.class.send(:define_method, name) do |value|
              self.send(self.aad_options[:value_singular].to_sym).send("field_#{field.id}=".to_sym, value)
            end
          else
            self.class.send(:define_method, name) do
              self.send(self.aad_options[:value_singular]).send("field_#{field.id}".to_sym, *args)
            end
          end
          #former only set the methods now we actually have to execute them
          send(name, *args)

        else
          # commenting out super because its throwing undefined method field_ changed in carrierwave? i think this is bad
          # super
        end  

      end

    end



  end

end