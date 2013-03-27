class StudentResidence < ActiveRecord::Base
	belongs_to :student
	belongs_to :residence
	
	def self.create_residence(student_rec, residence_hash)
		residence_hash[:town] = residence_hash[:town].strip()
		residence_hash[:state] = residence_hash[:state].strip()
		residence_hash[:country] = residence_hash[:country].strip()
		rec = Residence.first(:conditions => [ 'town = ? AND state = ? AND country = ?', residence_hash[:town], residence_hash[:state], residence_hash[:country]])
		if rec == nil
			rec = Residence.create(residence_hash)
		end
		sr = StudentResidence.find_by_student_id_and_residence_id(student_rec.id, rec.id)
		if sr == nil
			StudentResidence.create(:student_id => student_rec.id, :residence_id => rec.id)
		end
	end

	def self.remove_student(student_id)
		recs = StudentResidence.find_all_by_student_id(student_id)
		recs.each { |rec|
			id = rec.residence_id
			rec.destroy()
			other = StudentResidence.find_by_residence_id(id)
			if other == nil # we've deleted the last one
				other = Residence.find(id)
				other.destroy
			end
		}
	end
end
