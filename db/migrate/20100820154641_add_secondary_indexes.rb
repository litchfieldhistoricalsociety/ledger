class AddSecondaryIndexes < ActiveRecord::Migration
  def self.up
    add_index :attended_years, :student_id
    add_index :government_posts, :student_id
    add_index :marriages, :student_id
    add_index :marriages, :spouse_id
    add_index :material_categories, :material_id
    add_index :material_categories, :category_id
    add_index :material_images, :material_id
    add_index :material_images, :image_id
    add_index :material_transcriptions, :material_id
    add_index :material_transcriptions, :transcription_id
    add_index :offsite_materials, :student_id
    add_index :relations, :student1_id
    add_index :relations, :student2_id
    add_index :student_materials, :student_id
    add_index :student_materials, :material_id
    add_index :student_political_parties, :student_id
    add_index :student_political_parties, :political_party_id
    add_index :student_professions, :student_id
    add_index :student_professions, :profession_id
    add_index :student_residences, :student_id
    add_index :student_residences, :residence_id
  end

  def self.down
    remove_index :attended_years, :student_id
    remove_index :government_posts, :student_id
    remove_index :marriages, :student_id
    remove_index :marriages, :spouse_id
    remove_index :material_categories, :material_id
    remove_index :material_categories, :category_id
    remove_index :material_images, :material_id
    remove_index :material_images, :image_id
    remove_index :material_transcriptions, :material_id
    remove_index :material_transcriptions, :transcription_id
    remove_index :offsite_materials, :student_id
    remove_index :relations, :student1_id
    remove_index :relations, :student2_id
    remove_index :student_materials, :student_id
    remove_index :student_materials, :material_id
    remove_index :student_political_parties, :student_id
    remove_index :student_political_parties, :political_party_id
    remove_index :student_professions, :student_id
    remove_index :student_professions, :profession_id
    remove_index :student_residences, :student_id
    remove_index :student_residences, :residence_id
  end
end
