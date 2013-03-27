class CreateStudentPoliticalParties < ActiveRecord::Migration
  def self.up
    create_table :student_political_parties do |t|
      t.decimal :student_id
      t.decimal :political_party_id

      t.timestamps
    end
  end

  def self.down
    drop_table :student_political_parties
  end
end
