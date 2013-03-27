class CreateStudents < ActiveRecord::Migration
  def self.up
    create_table :students do |t|
      t.string :name
      t.string :sort_name
      t.string :other_name
      t.string :gender
      t.text :room_and_board
      t.string :home_town
      t.string :home_state
      t.string :home_country
      t.string :born
      t.string :died
      t.text :other_education
      t.string :admitted_to_bar
      t.text :training_with_other_lawyers
      t.text :federal_committees
      t.text :state_committees
      t.text :biographical_notes
      t.string :citation_of_attendance
      t.decimal :image_id
      t.text :secondary_sources
      t.text :additional_notes
	  t.text :private_notes
	  t.text :benevolent_and_charitable_organizations
	  t.string :is_stub

      t.timestamps
    end
  end

  def self.down
    drop_table :students
  end
end
