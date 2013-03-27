class CreateStudentResidences < ActiveRecord::Migration
  def self.up
    create_table :student_residences do |t|
      t.decimal :student_id
      t.decimal :residence_id

      t.timestamps
    end
  end

  def self.down
    drop_table :student_residences
  end
end
