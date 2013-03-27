class CreateRelations < ActiveRecord::Migration
  def self.up
    create_table :relations do |t|
      t.decimal :student1_id
      t.decimal :student2_id
      t.string :relationship

      t.timestamps
    end
  end

  def self.down
    drop_table :relations
  end
end
