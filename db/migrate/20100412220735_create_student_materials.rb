class CreateStudentMaterials < ActiveRecord::Migration
  def self.up
    create_table :student_materials do |t|
      t.decimal :student_id
      t.decimal :material_id
      t.string :relationship

      t.timestamps
    end
  end

  def self.down
    drop_table :student_materials
  end
end
