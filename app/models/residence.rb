class Residence < ActiveRecord::Base
	has_many :student_residences
	has_many :students, :through => :student_residences
end
