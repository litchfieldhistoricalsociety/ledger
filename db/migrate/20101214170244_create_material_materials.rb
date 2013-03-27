class CreateMaterialMaterials < ActiveRecord::Migration
  def self.up
    create_table :material_materials do |t|
      t.decimal :material1_id
      t.decimal :material2_id
      t.string :description1
      t.string :description2

      t.timestamps
    end
  end

  def self.down
    drop_table :material_materials
  end
end
