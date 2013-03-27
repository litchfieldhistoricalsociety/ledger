class CreateMaterials < ActiveRecord::Migration
  def self.up
    create_table :materials do |t|
      t.string :name
      t.string :object_id
      t.string :accession_num
      t.string :url
      t.string :author
      t.string :material_date
      t.string :collection
      t.string :held_at
      t.string :associated_place
      t.string :medium
      t.string :size
      t.text :description
	  t.text :private_notes

      t.timestamps
    end
  end

  def self.down
    drop_table :materials
  end
end
