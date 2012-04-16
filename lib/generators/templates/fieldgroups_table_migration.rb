class Create<%= fieldgroup_klass_name.pluralize %> < ActiveRecord::Migration
  def change
    create_table :<%= fieldgroup_table_name %> do |t|  
      t.string :name
      t.timestamps
    end
    change_table :<%= fieldgroup_table_name %> do |t|
      t.index :name
    end
  end
end