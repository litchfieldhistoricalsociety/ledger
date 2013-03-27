class Marriage < ActiveRecord::Base
	belongs_to :student

	def self.create_marriage(student, spouse_info, date)
		spouse_info[:gender] = student.gender == 'F' ? 'M' : 'F'
		if spouse_info[:name] == 'Unknown' || spouse_info[:name] == 'unknown'
			Marriage.create({ :student_id => student.id, :marriage_date => date, :spouse_id => nil })
		else
			spouse_rec = Relation.create_relationship('spouse', spouse_info, student)
			if spouse_rec
				# always create the record with the student_id numerically lower than the spouse_id. That will keep duplicates from happening
				first = student.id > spouse_rec.id ? spouse_rec.id : student.id
				second = student.id > spouse_rec.id ? student.id : spouse_rec.id
				mar = Marriage.find_by_student_id_and_spouse_id(first, second)
				if mar == nil
					Marriage.create({ :student_id => first, :marriage_date => date, :spouse_id => second })
				end
			else
				puts "Marriage record not created for #{spouse_rec.name}"
			end
		end
	end

	def self.remove_student(student_id)
		recs = Marriage.find_all_by_student_id(student_id)
		recs.each { |rec|
			rec.destroy()
		}
		recs = Marriage.find_all_by_spouse_id(student_id)
		recs.each { |rec|
			rec.destroy()
		}
	end
end
