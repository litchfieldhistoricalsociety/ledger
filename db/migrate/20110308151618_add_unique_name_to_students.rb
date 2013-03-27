class AddUniqueNameToStudents < ActiveRecord::Migration
  def self.up
    add_column :students, :original_name, :string

	recs = Student.all
	recs.each { |rec|
		rec.original_name = rec.name
		rec.save!
	}

  end

  def self.down
    remove_column :students, :original_name
  end
end
