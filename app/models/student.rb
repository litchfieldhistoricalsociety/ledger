class Student < ActiveRecord::Base
	attr :years_attended, true
	attr :school, true
	attr :years_attended_lls, true
	attr :years_attended_lfa, true
	has_many :student_professions
	has_many :professions, :through => :student_professions
	has_many :student_political_parties
	has_many :political_parties, :through => :student_political_parties
	has_many :student_residences
	has_many :residences, :through => :student_residences
	has_many :student_materials
	has_many :materials, :through => :student_materials
	has_many :marriages
	has_many :government_posts
	has_many :offsite_materials

	validates :name, :presence => true
	validate :legal_born?
	validate :legal_died?
#
#	def legal_number?
#		if object_id.blank? && accession_num.blank?
#			errors.add(:id, "You must specify either an Object Id or an Assession Number")
#		end
#	end
	def legal_born?
		if born && born.length > 0
			d = VagueDate.factory(born)
			errors.add(:born, d) if d.kind_of?(String)
		end
	end
	
	def legal_died?
		if died && died.length > 0
			d = VagueDate.factory(died)
			errors.add(:died, d) if d.kind_of?(String)
		end
	end

	def to_solr()
		yrs = AttendedYear.find_all_by_student_id(self.id)
		schools = AttendedYear.to_school_string(yrs).split(',')
		years = []
		yrs.each {|y|
			years.push("#{y.year}")
		}

		residences = []
		self.residences.each { |rec|
			residences.push("#{rec.town} #{rec.state} #{rec.country}")
		}

		married = []
		self.marriages.each { |rec|
			married.push(VagueDate.year(rec.marriage_date))
		}

		solr = { :id => self.id,
			:doc_type => 'student',
			:name => self.name,
			:ac_name => self.name,
			:name_sort => self.sort_name,
			:other_name => self.other_name,
#			:gender => self.gender,
			:room_and_board => self.room_and_board,
			:home_town => self.home_town,
			:home_state => self.home_state,
#			:marriage_date => VagueDate.year(self.marriage_date),
			:born => VagueDate.years(self.born),
			:died => VagueDate.years(self.died),
			:other_education => self.other_education,
			:admitted_to_bar => self.admitted_to_bar,
			:training_with_other_lawyers => self.training_with_other_lawyers,
			:federal_committees => self.federal_committees,
			:state_committees => self.state_committees,
			:biographical_notes => self.biographical_notes,
			:citation_of_attendance => self.citation_of_attendance,
			:secondary_sources => self.secondary_sources,
			:additional_notes => self.additional_notes,
			:benevolent_and_charitable_organizations => self.benevolent_and_charitable_organizations,

			:profession => get_arr_from_secondary_table(self.professions),
			:government_post => get_arr_from_secondary_table(self.government_posts),
			:political_party => get_arr_from_secondary_table(self.political_parties),
			:attended_year => years,
			:other_residence => residences,
			:school => schools
		}
		return solr
	end

	def generate_unique_name()
		others = Student.find_all_by_original_name(self.original_name)
		if others.length == 0 || (others.length == 1 && others[0].id == self.id)
			self.name = self.original_name
			return false
		end

		# use both birth and death dates if available, or just one if not.
		if self.born && self.born.length > 0
			if self.died && self.died.length > 0
				self.name  = "#{self.original_name} (#{VagueDate.year(self.born)}-#{VagueDate.year(self.died)})"
			else
				self.name = "#{self.original_name} (b. #{VagueDate.year(self.born)})"
			end
		else
			if self.died && self.died.length > 0
				self.name = "#{self.original_name} (d. #{VagueDate.year(self.died)})"
			else
				# There was neither a birth or death date, so try the attended years
				self.fill_record()
				if self.years_attended && self.years_attended.length > 0
					self.name = "#{self.original_name} (attended: #{self.years_attended})"
				else
					self.name = self.original_name	# give up: what should we use here?
				end
			end
		end

		# now be sure that it is unique
		matches = Student.find_all_by_name(self.name)
		index = 2
		ideal_unique_name = self.name
		while matches.length > 1 || (matches.length == 1 && matches[0].id != self.id)
			self.name = "#{ideal_unique_name} #{index}"
			index += 1
			matches = Student.find_all_by_name(self.name)
		end
		return true
	end

	def get_arr_from_secondary_table(all)
		return nil if all == nil
		arr = []
		all.each {|rec|
			arr.push(rec.title)
		}
		return arr
	end

	def fill_record()
		yrs = AttendedYear.find_all_by_student_id(self.id)
		self.years_attended = AttendedYear.to_friendly_string(yrs)
		self.school = AttendedYear.to_school_string(yrs)
		lls = []
		lfa = []
		yrs.each {|yr|
			if yr['school'] == 'LLS'
				lls.push(yr)
			else
				lfa.push(yr)
			end
		}
		self.years_attended_lls = AttendedYear.to_friendly_string(lls)
		self.years_attended_lfa = AttendedYear.to_friendly_string(lfa)
	end

	def self.convert_solr_response(docs)
		recs = []
		docs.each {|doc|
			if doc['doc_type'] == 'student'
				arr = doc['id'].split('_')
				if arr.length == 2 && arr[0] == 'student'
					rec = Student.find_by_id(arr[1])
					if rec != nil
						rec.fill_record()
						recs.push(rec)
					else
						puts "Solr returned a student record that is not in the database: #{doc['name']}"
					end
				else
					puts "Solr returned a record of type #{arr[0]} when expecting a student: #{doc['name']}"
				end
			elsif doc['doc_type'] == 'material'
				rec = Material.convert_solr_response(doc)
				recs.push(rec) if rec
			else
				puts "Solr returned a record of type #{doc['doc_type']}: #{doc['name']}"
			end
		}
		return recs
	end

	def self.assemble_date_query_string(params, solr_field, key_type, key_first, key_second)
		if params[key_first] && params[key_first].length > 0
			if params[key_type] == 'Exactly'
				return "#{solr_field}:#{params[key_first]}"
			elsif params[key_type] == 'Before'
				return "#{solr_field}:[* TO #{params[key_first]}]"
			elsif params[key_type] == 'After'
				return "#{solr_field}:[#{params[key_first]} TO *]"
			elsif params[key_type] == 'Between'
				if params[key_second] && params[key_second].length > 0
					return "#{solr_field}:[#{params[key_first]} TO #{params[key_second]}]"
				end
			end
		end
		return nil
	end

	def self.create_query_string(params)
		arr = []
		#if (params[:LLS] && params[:LLS].length > 0) || (params[:LFA] && params[:LFA].length > 0)
			arr.push("doc_type:student")
		#end
		if params[:q] && params[:q].length > 0
			a = params[:q].split(' ')
			arr.push(a.join(' AND '))
		end
		if params[:name] && params[:name].length > 0
			arr.push( "name:#{params[:name]}")
		end
		if params[:LLS] && params[:LLS].length > 0 && params[:LFA] && params[:LFA].length > 0
			arr.push( "(school:LLS OR school:LFA)")
		elsif params[:LLS] && params[:LLS].length > 0
			arr.push( "school:LLS")
		elsif params[:LFA] && params[:LFA].length > 0
			arr.push( "school:LFA")
		end
		if params[:other_education] && params[:other_education].length > 0
			arr.push( "other_education:#{params[:other_education]}")
		end
		if params[:profession] && params[:profession].length > 0
			arr.push( "profession:#{params[:profession]}")
		end
		str = self.assemble_date_query_string(params, 'attended_year', :year_attended_type, :year_attended_first, :year_attended_second)
		arr.push(str) if str
		str = self.assemble_date_query_string(params, 'born', :born_type, :born_first, :born_second)
		arr.push(str) if str
		str = self.assemble_date_query_string(params, 'died', :died_type, :died_first, :died_second)
		arr.push(str) if str
		return arr.join(' AND ')
	end

	def has_profession_category()
		# this checks to see if all of the profession type fields are blank.
		return true if self.professions != nil && self.professions.length > 0
		return true if self.political_parties != nil && self.political_parties.length > 0
		return true if self.admitted_to_bar != nil && self.admitted_to_bar.length > 0
		return true if self.training_with_other_lawyers != nil && self.training_with_other_lawyers.length > 0
		return true if self.federal_committees != nil && self.federal_committees.length > 0
		return true if self.state_committees != nil && self.state_committees.length > 0
		return true if self.political_parties != nil && self.political_parties.length > 0
		return true if self.government_posts != nil && self.government_posts.length > 0
		return false
	end

	def has_education_category()
		return true if self.years_attended != nil && self.years_attended.length > 0
		return true if self.other_education != nil && self.other_education.length > 0
		return true if self.room_and_board != nil && self.room_and_board.length > 0
		return false
	end

	def self.make_sort_name(name)
		# the sort name begins on the last word before a comma, or the last word.
		arr = name.split(',')
		puts "Weird commas: #{name}" if arr.length > 2
		if arr.length > 1
			# arr[0] is the first part of the name, arr[1] contains the Jr.
			arr2 = arr[0].split(' ')
			ln = arr2.pop()
			arr2 = arr2.unshift(ln)
			arr2[0] += arr[1] + ','
			return arr2.join(' ')
		else
			name = "--Unknown--" if name.length == 0
			arr = name.split(' ')
			ln = arr.pop()
			arr = arr.unshift(ln+',')
			return arr.join(' ')
		end
	end

	def self.get_or_create(info)
		rec = Student.find_by_name(info[:name])
		return rec if rec != nil
		return Student.create_stub(info)
	end

	def self.create_stub(info)
		info[:name] = info[:name].sub(/(Miss\s+)|(Mr\.?\s+)|(Mrs\.?\s+)|(Ms\.?\s+)/, '').strip()
		if info[:name].length < 2 # || info[:name].index('nknown') != nil
			return nil
		end

		info[:is_stub] = true
		info[:original_name] = info[:name]
		info[:sort_name] = Student.make_sort_name(info[:name])
		return Student.create(info)
	end

	def remove_references()
		# This removes all the other entries in other tables for this student
		recs = AttendedYear.find_all_by_student_id(self.id)
		recs.each { |rec| rec.destroy() }
		recs = GovernmentPost.find_all_by_student_id(self.id)
		recs.each { |rec| rec.destroy() }
		recs = Marriage.find_all_by_student_id(self.id)
		recs.each { |rec| rec.destroy() }
		recs = Marriage.find_all_by_spouse_id(self.id)
		recs.each { |rec| rec.destroy() }
		recs = OffsiteMaterial.find_all_by_student_id(self.id)
		recs.each { |rec| rec.destroy() }
		recs = Relation.find_all_by_student1_id(self.id)
		recs.each { |rec| rec.destroy() }
		recs = Relation.find_all_by_student2_id(self.id)
		recs.each { |rec| rec.destroy() }
		recs = StudentMaterial.find_all_by_student_id(self.id)
		recs.each { |rec| rec.destroy() }
		recs = StudentPoliticalParty.find_all_by_student_id(self.id)
		recs.each { |rec|
			id = rec.political_party_id
			rec.destroy()
			other = StudentPoliticalParty.find_by_political_party_id(id)
			if other == nil # we've deleted the last one
				other = PoliticalParty.find(id)
				other.destroy
			end
		}
		recs = StudentProfession.find_all_by_student_id(self.id)
		recs.each { |rec|
			id = rec.profession_id
			rec.destroy()
			other = StudentProfession.find_by_profession_id(id)
			if other == nil # we've deleted the last one
				other = StudentProfession.find(id)
				other.destroy
			end
		}
		recs = StudentResidence.find_all_by_student_id(self.id)
		recs.each { |rec|
			id = rec.residence_id
			rec.destroy()
			other = StudentResidence.find_by_residence_id(id)
			if other == nil # we've deleted the last one
				other = StudentResidence.find(id)
				other.destroy
			end
		}
	end
end
