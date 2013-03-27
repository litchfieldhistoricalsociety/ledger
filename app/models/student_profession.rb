class StudentProfession < ActiveRecord::Base
	belongs_to :student
	belongs_to :profession

	def self.add_connection(student_id, profession_id)
		self.create({ :student_id  => student_id, :profession_id => profession_id })
	end

	def self.add(student_id, profession_name)
		profession = Profession.find_by_title(profession_name)
		if profession == nil
			profession = Profession.create({:title => profession_name})
		end
		self.add_connection(student_id, profession.id)
	end

	def self.remove_student(student_id)
		recs = StudentProfession.find_all_by_student_id(student_id)
		recs.each { |rec|
			id = rec.profession_id
			rec.destroy()
			other = StudentProfession.find_by_profession_id(id)
			if other == nil # we've deleted the last one
				other = Profession.find(id)
				other.destroy
			end
		}
	end
end
