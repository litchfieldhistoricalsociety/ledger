class AddMaterialCommentToStudentMaterials < ActiveRecord::Migration
  def self.up
    add_column :student_materials, :material_comment, :string
  end

  def self.down
    remove_column :student_materials, :material_comment
  end
end
