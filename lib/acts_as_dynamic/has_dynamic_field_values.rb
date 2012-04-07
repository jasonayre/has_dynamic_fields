require "active_record"
module ActsAsDynamic

  module HasDynamicFieldValues
    def has_dynamic_field_values(options = {})
      
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
      options[:field_foreign_key] ||= options[:field_class_name].tableize.singularize.to_sym
      options[:field_plural] ||= options[:field_class_name].tableize
      
      options[:fieldgroup_class_name] ||= "DynamicFieldGroup"
      options[:fieldgroup_table_name] ||= options[:fieldgroup_class_name].tableize
      options[:fieldgroup_foreign_key] ||= options[:fieldgroup_class_name].tableize.singularize.to_sym
      options[:fieldgroup_singular] ||= options[:fieldgroup_class_name].tableize.singularize
      options[:fieldgroup_plural] ||= options[:fieldgroup_class_name].tableize
      
      options[:entity_klass] = options[:entity_class_name].constantize
      options[:field_klass] = options[:field_class_name].constantize
      options[:value_klass] = options[:value_class_name].constantize
      options[:fieldgroup_klass] = options[:fieldgroup_class_name].constantize
      
      cattr_accessor :aad_options
      self.aad_options ||= Hash.new

      # Return if already present
      return if self.aad_options.keys.include? options[:entity_class_name]
      
      self.aad_options = options
      
      include InstanceMethods
      
      entity_klass = options[:entity_class_name].constantize
      field_klass = options[:field_class_name].constantize
      value_klass = options[:value_class_name].constantize
      fieldgroup_class = options[:fieldgroup_class_name].constantize
      
      #eval entity class
      class_eval do
        
        #this can be confusing, because I chose to use a horizontal scaling eav pattern due to file upload/carrierwave, 
        #this may not make a ton of sense if you look at it out of context and without looking @ your db.
        #entity has one value, but that value row contains all the possible field values, entity type specific field values..
        #are controlled through fieldgroup, each entity has 1 fieldgroup (category,channel,type, whatever), and 1 value row
        
        has_one options[:value_singular].to_sym
        accepts_nested_attributes_for options[:value_singular].to_sym, :allow_destroy => true
        
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
            puts "I should be writing #{attribute_name}"
            self.class.send(:define_method, name) do |value|
              self.send(self.aad_options[:value_singular].to_sym).send("field_#{field.id}=".to_sym, value)
            end
            
          else
            puts "i should be reading #{attribute_name}"
            self.class.send(:define_method, name) do
              self.send(self.aad_options[:value_singular]).send("field_#{field.id}".to_sym, *args)
            end
          end
          #former only set the methods no we actually have to execute them
          send(name, *args)

        else
          # commenting out super because its throwing undefined method field_ changed in carrierwave? i think this is bad
          # super
        end  

      end
      
    end



  end
  
end