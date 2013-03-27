class StudentPoliticalParty < ActiveRecord::Base
	belongs_to :student
	belongs_to :political_party

	def self.add_connection(student_id, party_id)
		self.create({ :student_id  => student_id, :political_party_id => party_id })
	end

	def self.add(student_id, party_name)
		party = PoliticalParty.find_by_title(party_name)
		if party == nil
			party = PoliticalParty.create({:title => party_name})
		end
		self.add_connection(student_id, party.id)
	end

	def self.remove_student(student_id)
		recs = StudentPoliticalParty.find_all_by_student_id(student_id)
		recs.each { |rec|
			id = rec.political_party_id
			rec.destroy()
			other = StudentPoliticalParty.find_by_political_party_id(id)
			if other == nil # we've deleted the last one
				other = PoliticalParty.find(id)
				other.destroy
			end
		}
	end
end
