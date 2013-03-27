class CreateOffsiteMaterials < ActiveRecord::Migration
  def self.up
    create_table :offsite_materials do |t|
      t.string :name
      t.string :url
	  t.decimal :student_id

      t.timestamps
    end
  end

  def self.down
    drop_table :offsite_materials
  end
end
