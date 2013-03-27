class CreateMaterialCategories < ActiveRecord::Migration
  def self.up
    create_table :material_categories do |t|
      t.decimal :material_id
      t.decimal :category_id

      t.timestamps
    end
  end

  def self.down
    drop_table :material_categories
  end
end
