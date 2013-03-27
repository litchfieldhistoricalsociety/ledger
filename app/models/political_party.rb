class PoliticalParty < ActiveRecord::Base
	has_many :student_political_parties
	has_many :students, :through => :student_political_parties
end
