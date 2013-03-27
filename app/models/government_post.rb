class GovernmentPost < ActiveRecord::Base
	belongs_to :student

	def self.remove_student(student_id)
		recs = GovernmentPost.find_all_by_student_id(student_id)
		recs.each { |rec|
			rec.destroy()
		}
	end
end
