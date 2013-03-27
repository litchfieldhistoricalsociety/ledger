class Profession < ActiveRecord::Base
	has_many :student_professions
	has_many :students, :through => :student_professions
end
