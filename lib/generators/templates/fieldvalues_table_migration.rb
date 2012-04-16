class Create<%= fieldvalues_klass_name.pluralize %> < ActiveRecord::Migration
  def change
    create_table :<%= fieldvalues_table_name %> do |t|
      t.integer :<%= entity_foreign_key %>
      <% if use_fieldgroup_table %>
      t.integer  :<%= fieldgroup_foreign_key %>
      <% end %>
      t.timestamps
    end
    
    change_table :<%= fieldvalues_table_name %> do |t|
      t.index :<%= entity_foreign_key %>
      <% if use_fieldgroup_table %>
      t.index  :<%= fieldgroup_foreign_key %>
      <% end %>
    end
    
  end
end
