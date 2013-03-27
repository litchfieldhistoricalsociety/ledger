class CreateMaterialImages < ActiveRecord::Migration
  def self.up
    create_table :material_images do |t|
      t.decimal :material_id
      t.decimal :image_id

      t.timestamps
    end
  end

  def self.down
    drop_table :material_images
  end
end
