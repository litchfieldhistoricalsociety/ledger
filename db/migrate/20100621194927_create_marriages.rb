class CreateMarriages < ActiveRecord::Migration
  def self.up
    create_table :marriages do |t|
      t.decimal :student_id
      t.string :marriage_date
      t.decimal :spouse_id

      t.timestamps
    end
  end

  def self.down
    drop_table :marriages
  end
end
