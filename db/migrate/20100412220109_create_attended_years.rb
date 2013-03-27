class CreateAttendedYears < ActiveRecord::Migration
  def self.up
    create_table :attended_years do |t|
      t.decimal :student_id
      t.string :school
      t.decimal :year
      t.string :comment

      t.timestamps
    end
  end

  def self.down
    drop_table :attended_years
  end
end
