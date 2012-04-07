class <%= migration_klass_name %> < ActiveRecord::Migration
  def change
    add_column :<%= table_name %>, :<%= column_name %>, :<%= column_type %>
  end
end