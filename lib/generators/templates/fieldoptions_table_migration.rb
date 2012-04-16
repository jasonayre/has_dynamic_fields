class Create<%= fieldoptions_klass_name.pluralize %> < ActiveRecord::Migration
  def change
    create_table :<%= fieldoptions_table_name %> do |t|
      t.string :label
      t.string :value
      t.integer :sort_order
      t.string :heading_text
      t.string :description
      t.string :image
      <% if use_fieldgroup_table %>
      t.integer  :<%= fieldgroup_foreign_key %>
      <% end %>
      t.timestamps
    end
    
    change_table :<%= fieldoptions_table_name %> do |t|
      <% if use_fieldgroup_table %>
      t.index  :<%= fieldgroup_foreign_key %>
      <% end %>
      t.index :label
    end
  end
end