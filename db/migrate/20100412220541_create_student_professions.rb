class CreateStudentProfessions < ActiveRecord::Migration
  def self.up
    create_table :student_professions do |t|
      t.decimal :student_id
      t.decimal :profession_id

      t.timestamps
    end
  end

  def self.down
    drop_table :student_professions
  end
end
