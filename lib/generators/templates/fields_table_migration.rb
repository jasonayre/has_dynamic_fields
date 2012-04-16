class Create<%= fields_klass_name.pluralize %> < ActiveRecord::Migration
  def change
    create_table :<%= fields_table_name %> do |t|
      <% if use_fieldgroup_table %>
      t.integer  :<%= fieldgroup_foreign_key %>
      <% end %>  
      t.string :name
      t.string :label
      t.string :placeholder
      t.string :fieldtype
      t.integer :sort_order
      t.string :button_text
      t.string :validation_method
    end
    change_table :<%= fields_table_name %> do |t|
      <% if use_fieldgroup_table %>
      t.index  :<%= fieldgroup_foreign_key %>
      <% end %>      
      t.index :name
      t.index :label
      t.index :fieldtype
    end
  end
end