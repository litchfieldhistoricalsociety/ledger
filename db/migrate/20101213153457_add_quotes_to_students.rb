class AddQuotesToStudents < ActiveRecord::Migration
  def self.up
    add_column :students, :quotes, :text
  end

  def self.down
    remove_column :students, :quotes
  end
end
