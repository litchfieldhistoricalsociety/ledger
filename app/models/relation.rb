class Relation < ActiveRecord::Base
	def self.create_relationship(relationship, info, student)
		# first try to find the record. If it doesn't exist, create a stub person
		# info is a partial student record
		rec = Student.get_or_create(info)
		if rec == nil
			puts "No name given in relationship field for #{student.name}"
			return nil
		end
		# don't create a duplicate record: that may happen if the relationship is defined in two different records
		exists = Relation.find_by_student1_id_and_student2_id(rec.id, student.id)
		if exists
			puts "Relationship doesn't match: #{Student.find(exists.student1_id).name} and #{Student.find(exists.student2_id).name}: #{exists.relationship} versus #{relationship}" if exists.relationship != relationship
			return rec
		end
		exists = Relation.find_by_student1_id_and_student2_id( student.id, rec.id)
		if exists
			puts "Relationship doesn't match: #{Student.find(exists.student1_id).name} and #{Student.find(exists.student2_id).name}: #{exists.relationship} versus #{relationship}" if exists.relationship != relationship
			return rec
		end
		relationship = 'child' if relationship == 'Daughter' || relationship == 'Son'
		relationship = 'parent' if relationship == 'Mother' || relationship == 'Father'
		relationship = 'spouse' if relationship == 'Wife' || relationship == 'Husband'
		relationship = 'sibling' if relationship == 'Sister' || relationship == 'Brother'
		if relationship == 'child'	# Reverse this
			Relation.create({ :student1_id => student.id, :student2_id => rec.id, :relationship => 'parent' })
		else
			Relation.create({ :student1_id => rec.id, :student2_id => student.id, :relationship => relationship })
		end
		return rec
	end

	def self.analyze_relationship(relationship, info, student_name)
		students = Student.find_all_by_original_name(student_name)
		others = Student.find_all_by_original_name(info[:name])
		if students.length == 0
			puts "#{student_name}: NOT FOUND"
		elsif students.length > 1
			puts "#{student_name}: AMBIGUOUS"
		elsif others.length == 0
			#puts "#{student_name}: STUB: #{info[:name]}"
			return true
		elsif others.length > 1
			puts "#{student_name}: AMBIGUOUS: #{info[:name]}"
		else
			exists = Relation.find_by_student1_id_and_student2_id(others[0].id, students[0].id)
			exists = Relation.find_by_student1_id_and_student2_id(students[0].id, others[0].id) if exists == nil
			if exists && exists.relationship != relationship
				puts "#{student_name}: MISMATCH: #{info[:name]} #{exists.relationship}/#{relationship}"
			else
				#puts "#{student_name}: CREATE: #{info[:name]} #{relationship}"
				return true
			end
		end
		return false
	end

	def self.remove_student(student_id)
		recs = Relation.find_all_by_student1_id(student_id)
		recs.each { |rec|
			rec.destroy()
		}
		recs = Relation.find_all_by_student2_id(student_id)
		recs.each { |rec|
			rec.destroy()
		}
	end

	def self.format_relation(relationship, flip, gender)
		return 'Daughter' if relationship == 'parent' && flip == true && gender == 'F'
		return 'Mother' if relationship == 'parent' && flip == false && gender == 'F'
		return 'Son' if relationship == 'parent' && flip == true && gender != 'F'
		return 'Father' if relationship == 'parent' && flip == false && gender != 'F'
		return 'Wife' if relationship == 'spouse' && gender == 'F'
		return 'Husband' if relationship == 'spouse' && gender != 'F'
		return 'Sister' if relationship == 'sibling' && gender == 'F'
		return 'Brother' if relationship == 'sibling' && gender != 'F'
		return "TODO: #{relationship}"
	end

end
