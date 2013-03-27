class ChangeCitationOfAttendanceToTextType < ActiveRecord::Migration
  def self.up
	  change_column :students, :citation_of_attendance, :text
  end

  def self.down
	  change_column :students, :citation_of_attendance, :string
  end
end
