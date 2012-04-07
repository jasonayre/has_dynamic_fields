class <%= migration_klass_name %> < ActiveRecord::Migration
  def change
    remove_column :<%= table_name %>, :<%= column_name %>
  end
end