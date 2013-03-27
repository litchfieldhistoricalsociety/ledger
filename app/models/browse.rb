# ------------------------------------------------------------------------
#     Copyright 2010 Litchfield Historical Society
# ----------------------------------------------------------------------------
class Browse
	def self.make_key(type, subtype, selection_id)
		return "#{SOLR_CORE}/#{type}/#{subtype}/#{selection_id}"
	end

	def self.invalidate()
		Rails.cache.clear()
	end

	def self.clear(type, subtype, selection_id)
		Rails.cache.delete(self.make_key(type, subtype, selection_id))
	end
	
	def self.clear_if(pattern)
		ActiveRecord::Base.logger.info("~~~~~ BROWSE clear_if: #{pattern}")
		keys = Rails.cache.fetch("keys")
		if keys
			new_keys = {}
			keys.each_key {|key|
				if key.match(pattern)
					Rails.cache.delete(key)
					ActiveRecord::Base.logger.info("        removed: #{key}")
				else
					new_keys[key] = true
					ActiveRecord::Base.logger.info("        kept: #{key}")
				end
			}
			Rails.cache.fetch("keys", :force => true) {
				new_keys
			}
		end
	end

	def self.student_changed(new_student, old_student)
		# TODO-PER: figure out what is different and invalidate the correct caches
		clear_lls = false
		clear_lfa = false
		if new_student
			clear_lls = AttendedYear.find_by_student_id_and_school(new_student.id, 'LLS') != nil
			clear_lfa = AttendedYear.find_by_student_id_and_school(new_student.id, 'LFA') != nil
			clear_non = !clear_lls && !clear_lfa
		end
		if old_student
			clear_lls = clear_lls || AttendedYear.find_by_student_id_and_school(old_student.id, 'LLS') != nil
			clear_lfa = clear_lfa || AttendedYear.find_by_student_id_and_school(old_student.id, 'LFA') != nil
			clear_non = clear_non || !clear_lls && !clear_lfa
		end
		self.clear_if(/^#{SOLR_CORE}\/LLS\//) if clear_lls
		self.clear_if(/^#{SOLR_CORE}\/LFA\//) if clear_lfa
		self.clear_if(/^#{SOLR_CORE}\/non\//) if clear_non
	end

	def self.material_changed(new_material, old_material)
		# TODO-PER: figure out what is different and invalidate the correct caches. The following invalidates too much.
		self.clear_if(/^#{SOLR_CORE}\/materials\//)
	end

	def self.warm_one(type, subtype, selection_id)
		puts "warming #{self.make_key(type, subtype, selection_id)}..."
		self.get(type, subtype, selection_id)
	end

	def self.warm()
		# just worry about getting the pages that are the slowest to load.
		self.warm_one('LLS', 'hometown', nil)
		self.warm_one('LFA', 'hometown', nil)
		self.warm_one('non', 'hometown', nil)
		students = Student.all(:group => 'home_country')
		students.each {|student|
			self.warm_one('LLS', 'hometown', student.home_country)
			self.warm_one('LFA', 'hometown', student.home_country)
			self.warm_one('non', 'hometown', student.home_country)
		}
		students = Student.find_all_by_home_country("United States", :group => 'home_state')
		students.each {|student|
			self.warm_one('LLS', 'hometown', "United States:#{student.home_state}")
			self.warm_one('LFA', 'hometown', "United States:#{student.home_state}")
			self.warm_one('non', 'hometown', "United States:#{student.home_state}")
		}

		self.warm_one('LLS', 'residences', nil)
		self.warm_one('LFA', 'residences', nil)
		self.warm_one('non', 'residences', nil)
		residences = Residence.all(:group => 'country')
		residences.each {|residence|
			self.warm_one('LLS', 'residences', residence.country)
			self.warm_one('LFA', 'residences', residence.country)
			self.warm_one('non', 'residences', residence.country)
		}
		residences = Residence.find_all_by_country("United States", :group => 'state')
		residences.each {|residence|
			self.warm_one('LLS', 'residences', "United States:#{residence.state}")
			self.warm_one('LFA', 'residences', "United States:#{residence.state}")
			self.warm_one('non', 'residences', "United States:#{residence.state}")
		}

		self.warm_one('LLS', 'profession', nil)
		self.warm_one('LFA', 'profession', nil)

		self.warm_one('LLS', 'political_party', nil)
		self.warm_one('LFA', 'political_party', nil)

		self.warm_one('LLS', 'name', 'A')
		self.warm_one('LLS', 'name', 'B')
		self.warm_one('LLS', 'name', 'C')
		self.warm_one('LLS', 'name', 'D')
		self.warm_one('LLS', 'name', 'E')
		self.warm_one('LLS', 'name', 'F')
		self.warm_one('LLS', 'name', 'G')
		self.warm_one('LLS', 'name', 'H')
		self.warm_one('LLS', 'name', 'I')
		self.warm_one('LLS', 'name', 'J')
		self.warm_one('LLS', 'name', 'K')
		self.warm_one('LLS', 'name', 'L')
		self.warm_one('LLS', 'name', 'M')
		self.warm_one('LLS', 'name', 'N')
		self.warm_one('LLS', 'name', 'O')
		self.warm_one('LLS', 'name', 'P')
		self.warm_one('LLS', 'name', 'Q')
		self.warm_one('LLS', 'name', 'R')
		self.warm_one('LLS', 'name', 'S')
		self.warm_one('LLS', 'name', 'T')
		self.warm_one('LLS', 'name', 'U')
		self.warm_one('LLS', 'name', 'W')
		self.warm_one('LLS', 'name', 'X')
		self.warm_one('LLS', 'name', 'Y')
		self.warm_one('LLS', 'name', 'Z')

		self.warm_one('LFA', 'name', 'A')
		self.warm_one('LFA', 'name', 'B')
		self.warm_one('LFA', 'name', 'C')
		self.warm_one('LFA', 'name', 'D')
		self.warm_one('LFA', 'name', 'E')
		self.warm_one('LFA', 'name', 'F')
		self.warm_one('LFA', 'name', 'G')
		self.warm_one('LFA', 'name', 'H')
		self.warm_one('LFA', 'name', 'I')
		self.warm_one('LFA', 'name', 'J')
		self.warm_one('LFA', 'name', 'K')
		self.warm_one('LFA', 'name', 'L')
		self.warm_one('LFA', 'name', 'M')
		self.warm_one('LFA', 'name', 'N')
		self.warm_one('LFA', 'name', 'O')
		self.warm_one('LFA', 'name', 'P')
		self.warm_one('LFA', 'name', 'Q')
		self.warm_one('LFA', 'name', 'R')
		self.warm_one('LFA', 'name', 'S')
		self.warm_one('LFA', 'name', 'T')
		self.warm_one('LFA', 'name', 'U')
		self.warm_one('LFA', 'name', 'W')
		self.warm_one('LFA', 'name', 'X')
		self.warm_one('LFA', 'name', 'Y')
		self.warm_one('LFA', 'name', 'Z')

		self.warm_one('non', 'name', 'A')
		self.warm_one('non', 'name', 'B')
		self.warm_one('non', 'name', 'C')
		self.warm_one('non', 'name', 'D')
		self.warm_one('non', 'name', 'E')
		self.warm_one('non', 'name', 'F')
		self.warm_one('non', 'name', 'G')
		self.warm_one('non', 'name', 'H')
		self.warm_one('non', 'name', 'I')
		self.warm_one('non', 'name', 'J')
		self.warm_one('non', 'name', 'K')
		self.warm_one('non', 'name', 'L')
		self.warm_one('non', 'name', 'M')
		self.warm_one('non', 'name', 'N')
		self.warm_one('non', 'name', 'O')
		self.warm_one('non', 'name', 'P')
		self.warm_one('non', 'name', 'Q')
		self.warm_one('non', 'name', 'R')
		self.warm_one('non', 'name', 'S')
		self.warm_one('non', 'name', 'T')
		self.warm_one('non', 'name', 'U')
		self.warm_one('non', 'name', 'W')
		self.warm_one('non', 'name', 'X')
		self.warm_one('non', 'name', 'Y')
		self.warm_one('non', 'name', 'Z')
	end

	def self.get_list_by_sql(sql, id_index, name_index, total_sql)
		if name_index.kind_of?(Array)
			sort_index = name_index[0]
			name_index = name_index[1]
		else
			sort_index = -1
		end
		recs = []
		match = ActiveRecord::Base.connection.execute(sql)
		match.each { |rec|
			if sort_index != -1
				recs.push({ :id => rec[id_index], 'name' => rec[name_index], 'sort_column' => rec[sort_index] })
			else
				recs.push({ :id => rec[id_index], 'name' => rec[name_index] })
			end
		}
		if sort_index != -1
			list = make_three_columns_sorted({ :recs => recs, :column => 'name', :sort_column => 'sort_column', :total_sql => total_sql })
		else
			list = make_three_columns({ :recs => recs, :column => 'name', :total_sql => total_sql })
		end
		return list
	end

	def self.get_names_by_sql(sql, id_index, name_index, sort_name_index)
		recs = []
		match = ActiveRecord::Base.connection.execute(sql)
		match.each { |rec|
			recs.push({ :id => rec[id_index], 'name' => rec[name_index], 'sort_name' => rec[sort_name_index] })
		}
		list = make_three_columns({ :recs => recs, :column => 'name', :sort_column => 'sort_name', :alt_text => method(:duplicate_student_format) })
		total = recs.length
		return [ list, total ]
	end

	def self.get(type, subtype, selection_id)
		key = make_key(type, subtype, selection_id)
		# create a special cached entry for the list of keys that have been requested. We first attempt to get the current
		# list of keys. For the first call, this will fail and we'll just create a hash with one key in it. After that, this will return
		# the full list of keys that have been requested.
		# then we call it again, but force the cache to fail. We add the current key to it so the cache now contains all the keys.
		keys = Rails.cache.fetch("keys") {
			{ key => true }
		}
		if keys[key] == nil
			Rails.cache.fetch("keys", :force => true) {
				keys.merge({ key => true })
			}
		end

		Rails.cache.fetch(key) {
			selection = nil
			list = nil
			sub_menu = nil
			sub_selection = nil
			total = 0
			country_total = nil
			if type == 'marriages'
				sql = "select distinct marriages.id from marriages inner join attended_years as ay1 on marriages.student_id = ay1.student_id inner join attended_years as ay2 on marriages.spouse_id = ay2.student_id"
				match = ActiveRecord::Base.connection.execute(sql)
				marriages = []
				match.each { |marriage_id|
					marriage = Marriage.find_by_id(marriage_id[0])
					student1 = Student.find_by_id(marriage.student_id)
					student2 = Student.find_by_id(marriage.spouse_id)
					guy = student1.gender == 'F' ? student2 : student1
					gal = student1.gender == 'F' ? student1 : student2
					label = "#{guy.name} and #{gal.name}"
					label += " (#{marriage.marriage_date})" if marriage.marriage_date && marriage.marriage_date.length > 0
					marriages.push({ :id => guy.id, 'name' => label, 'sort_name' => guy.sort_name })
				}
				list = make_three_columns({ :recs => marriages, :column => 'sort_name', :show_column => 'name', :alt_text => method(:duplicate_student_format), :num_cols => 2 })
				total = marriages.length

			####################### NON STUDENTS ###########################################
			elsif type == 'non'	# TODO-PER: This could be refactored in with the LLS and LFA types.
				if subtype == 'profession'
					all_sql = "select students.id,students.name,students.sort_name,professions.id,professions.title from students left outer join attended_years on students.id = attended_years.student_id inner join student_professions on students.id = student_professions.student_id inner join professions on student_professions.`profession_id` = professions.id where school is null"
					if selection_id == nil
						sql = "#{all_sql} group by professions.title"
						total_sql = "#{all_sql} and profession_id = $$$ID$$$"
						list = self.get_list_by_sql(sql, 3, 4, total_sql)
					else
						profession = Profession.find_by_id(selection_id)
						selection = profession.title
						sql = "#{all_sql} and professions.title = '#{profession.title.gsub("'") { |apos| "\\'" }}'"
						list, total = self.get_names_by_sql(sql, 0, 1, 2)
					end

				elsif subtype == 'political_party'
					all_sql = "select students.id,students.name,students.sort_name,political_parties.id,political_parties.title from students left outer join attended_years on students.id = attended_years.student_id inner join student_political_parties on students.id = student_political_parties.student_id inner join political_parties on student_political_parties.`political_party_id` = political_parties.id where school is null"
					if selection_id == nil
						sql = "#{all_sql} group by political_parties.title"
						total_sql = "#{all_sql} and political_party_id = $$$ID$$$"
						list = self.get_list_by_sql(sql, 3, 4, total_sql)
					else
						political_party = PoliticalParty.find_by_id(selection_id)
						selection = political_party.title
						sql = "#{all_sql} and political_parties.title = '#{political_party.title.gsub("'") { |apos| "\\'" }}'"
						list, total = self.get_names_by_sql(sql, 0, 1, 2)
					end
				elsif subtype == 'other_education'
					all_sql = "select students.id,students.name,students.sort_name,students.other_education from students left outer join attended_years on students.id = attended_years.student_id where school is null and other_education is not null and other_education != ''"
					if selection_id == nil
						sql = "#{all_sql} group by students.other_education"
						total_sql = "#{all_sql} and students.other_education = '$$$COLUMN$$$'"
						list = self.get_list_by_sql(sql, 0, 3, total_sql)
					else
						student = Student.find_by_id(selection_id)
						val = student.other_education
						val = val.gsub("'") { |apos| "\\'" }
						selection = student.other_education
						sql = "#{all_sql} and other_education='#{val}'"
						list, total = self.get_names_by_sql(sql, 0, 1, 2)
					end
				elsif subtype == 'political_office'
					all_sql = "select students.id,students.name,students.sort_name,government_posts.id,government_posts.which,government_posts.title from students left outer join attended_years on students.id = attended_years.student_id inner join government_posts on students.id = government_posts.student_id where school is null"
					if selection_id == nil
						sql = "#{all_sql} group by government_posts.which,government_posts.title"
						total_sql = "#{all_sql} and government_posts.which='$$$SORT_COLUMN$$$' and government_posts.title='$$$COLUMN$$$'"
						list = self.get_list_by_sql(sql, 3, [4,5], total_sql)
					else
						post = GovernmentPost.find_by_id(selection_id)
						if (post)
							sql = "#{all_sql} and government_posts.which = '#{post.which}' and government_posts.title = '#{post.title.gsub("'") { |apos| "\\'" }}'"
							selection = "#{post.which}: #{post.title}"
							list, total = self.get_names_by_sql(sql, 0, 1, 2)
						else
							selection = ""
							list = [[], [], []]
						end
					end

				elsif subtype == 'hometown'
					#all_sql = "select students.id,students.name,students.sort_name,students.home_town,students.home_state,students.home_country from students left outer join attended_years on students.id = attended_years.student_id where school is null and (home_town is not null or home_state is not null or home_country is not null) and (home_town != '' or home_state != '' or home_country != '')"
					if selection_id == nil
						selection = "United States"
						sub_selection = "CT"
					else
						arr = selection_id.split(':')
						if arr.length == 1
							selection = arr[0]
							sub_selection = selection == 'United States' ? "CT" : ""
						else
							selection = arr[0]
							sub_selection = arr[1]
							sub_selection = "" if sub_selection == "[Unknown]"
						end
					end

					# This gets a list of all the unique home_states for students not in a school
					students = Student.all()
					# weed out students from the schools
					students.delete_if {|student|
						student.fill_record()
						student.school.include?('LLS') || student.school.include?('LFA') || student.home_country == nil || student.home_country.length == 0
					}
					# get rid of duplicates
					students = students.sort { |a,b|
						if a.home_country == b.home_country
							astate = a.home_state == nil ? "" : a.home_state
							bstate = b.home_state == nil ? "" : b.home_state
							astate <=> bstate
						else
							a.home_country <=> b.home_country
						end
					}
					last_state = "$$$$$$$$$$"
					students.delete_if {|student|
						temp = last_state
						last_state = "#{student['home_country']}:#{student['home_state']}"
						"#{student['home_country']}:#{student['home_state']}" == temp
					}

					sub_menu = {}
					students.each { |student|
						if sub_menu[student['home_country']] == nil
							sub_menu[student['home_country']] = []
						end
						state = student['home_state'] == nil || student['home_state'].length == 0 ? "[Unknown]" : student['home_state']
						sub_menu[student['home_country']].push(state)
					}
					if sub_selection == ""
						sub_selection = sub_menu[selection] ? sub_menu[selection][0] : "[Unknown]"
					end

					state = sub_selection == "[Unknown]" ? "" : sub_selection
					students = Student.find_all_by_home_country_and_home_state(selection, state)
					students.delete_if {|student|
						student.fill_record()
						student.school.include?('LLS') || student.school.include?('LFA')
					}
					if selection == 'United States'
						stus = Student.find_all_by_home_country(selection)
						stus.delete_if {|student|
							student.fill_record()
							student.school.include?('LLS') || student.school.include?('LFA')
						}
						country_total = stus.length
					end
					list = make_three_columns_sorted({ :recs => students, :column => 'sort_name', :sort_column => 'home_town', :show_column => 'name', :alt_text_proc => method(:duplicate_student_format), :header_totals => true })
					total = students.length

				elsif subtype == 'residences'
					if selection_id == nil
						selection = "United States"
						sub_selection = "CT"
					else
						arr = selection_id.split(':')
						if arr.length == 1
							selection = arr[0]
							sub_selection = selection == 'United States' ? "CT" : ""
						else
							selection = arr[0]
							sub_selection = arr[1]
							sub_selection = "" if sub_selection == "[Unknown]"
						end
					end
					residences = Residence.all()
					# weed out students from the other school
					residences.delete_if {|residence|
						sr = StudentResidence.find_all_by_residence_id(residence.id)
						found = false
						sr.each { |r|
							student = Student.find(r.student_id)
							student.fill_record()
							found = true if !student.school.include?('LLS') && !student.school.include?('LFA')
						}
						!found	# this is the return value for delete_if
					}
					# get rid of duplicates
					residences = residences.sort { |a,b|
						if a.country == b.country
							astate = a.state == nil ? "" : a.state
							bstate = b.state == nil ? "" : b.state
							astate <=> bstate
						else
							a.country <=> b.country
						end
					}
					last_state = "$$$$$$$$$$"
					residences.delete_if {|residence|
						temp = last_state
						last_state = "#{residence['country']}:#{residence['state']}"
						"#{residence['country']}:#{residence['state']}" == temp
					}

					sub_menu = {}
					residences.each { |residence|
						if sub_menu[residence['country']] == nil
							sub_menu[residence['country']] = []
						end
						state = residence['state'] == nil || residence['state'].length == 0 ? "[Unknown]" : residence['state']
						sub_menu[residence['country']].push(state)
					}
					if sub_selection == ""
						sub_selection = sub_menu[selection] ? sub_menu[selection][0] : "[Unknown]"
					end

					state = sub_selection == "[Unknown]" ? "" : sub_selection
					residences = Residence.find_all_by_country_and_state(selection, state)
					students = []
					residences.each { |residence|
						sr = StudentResidence.find_all_by_residence_id(residence.id)
						sr.each { |rec|
							student = Student.find_by_id(rec.student_id)
							student.fill_record()
							student.home_town = residence.town	# hack to make the make_three_columns_sorted method work. Just don't save the record!
							students.push(student) if !student.school.include?('LLS') || !student.school.include?('LFA')
						}
					}
					if selection == 'United States'
						residences = Residence.find_all_by_country(selection)
						stus = {}
						residences.each { |residence|
							sr = StudentResidence.find_all_by_residence_id(residence.id)
							sr.each { |rec|
								student = Student.find_by_id(rec.student_id)
								student.fill_record()
								stus[student.id] = 'true' if !student.school.include?('LLS') || !student.school.include?('LFA')
							}
						}
						country_total = stus.length
					end
					list = make_three_columns_sorted({ :recs => students, :column => 'sort_name', :sort_column => 'home_town', :show_column => 'name', :alt_text_proc => method(:duplicate_student_format), :header_totals => true })
					total = students.length

				elsif subtype == 'name'
					selection_id = 'A' if selection_id == nil
					arr = selection_id.split('-')
					students = []
					search = arr[0]+ '%'
					students += Student.all(:conditions => [ "sort_name LIKE ?", search])
					if arr.length > 1
						search = arr[1]+ '%'
						students += Student.all(:conditions => [ "sort_name LIKE ?", search])
					end
					students.delete_if {|student|
						student.fill_record()
						student.school.include?('LLS') || student.school.include?('LFA')
					}
					selection = selection_id
					list = make_three_columns({ :recs => students, :column => 'sort_name', :show_column => 'name', :alt_text => method(:duplicate_student_format) })

				end

			##################################### LLS, LFA #######################
			elsif type != 'materials'	# do this part for the people, only.
				if subtype == 'profession'
					if selection_id == nil
						professions = Profession.all()
						professions.delete_if {|profession|
							students = profession.students
							found_one = false
							students.each {|student|
								student.fill_record()
								found_one = true if student.school.include?(type)
							}
							found_one == false
						}
						sql = "select  distinct student_professions.student_id from `student_professions` inner join attended_years on student_professions.student_id = `attended_years`.`student_id`  where profession_id = $$$ID$$$ and school='#{type}'"
						list = make_three_columns({ :recs => professions, :column => 'title', :total_sql => sql })
					else
						profession = Profession.find_by_id(selection_id)
						if profession != nil
							students = profession.students
							students.delete_if {|student|
								student.fill_record()
								!student.school.include?(type)
							}
							selection = profession.title
							list = make_three_columns({ :recs => students, :column => 'sort_name', :show_column => 'name', :alt_text => method(:duplicate_student_format) })
							total = students.length
						else
							selection = ""
							list = [[], [], []]
						end
					end

					elsif subtype == 'political_party'
						if selection_id == nil
							political_parties = PoliticalParty.all()
							political_parties.delete_if {|political_party|
								students = political_party.students
								found_one = false
								students.each {|student|
									student.fill_record()
									found_one = true if student.school.include?(type)
								}
								found_one == false
							}
							sql = "select  distinct student_political_parties.student_id from `student_political_parties` inner join attended_years on student_political_parties.student_id = `attended_years`.`student_id`  where political_party_id = $$$ID$$$ and school='#{type}'"
							list = make_three_columns({ :recs => political_parties, :column => 'title', :total_sql => sql })
						else
							political_party = PoliticalParty.find_by_id(selection_id)
							if political_party != nil
								students = political_party.students
								students.delete_if {|student|
									student.fill_record()
									!student.school.include?(type)
								}
								selection = political_party.title
								list = make_three_columns({ :recs => students, :column => 'sort_name', :show_column => 'name', :alt_text => method(:duplicate_student_format) })
								total = students.length
							else
								selection = ""
								list = [[], [], []]
							end
						end

					elsif subtype == 'other_education'
						if selection_id == nil
							sql = "select distinct students.other_education,students.id from `students` inner join attended_years on students.id = `attended_years`.`student_id` where school='#{type}'"
							match = ActiveRecord::Base.connection.execute(sql)
							educations = []
							match.each { |education|
								if education[0].length > 0
									educations.push({ :id => education[1], :title => education[0] })
								end
							}
							educations.uniq! { |e| e[:title]}
							sql = "select distinct students.id from `students` inner join attended_years on students.id = `attended_years`.`student_id` where other_education='$$$COLUMN$$$' and school='#{type}'"
							list = make_three_columns({ :recs => educations, :column => :title, :total_sql => sql })
						else
							student = Student.find_by_id(selection_id)
							students = []
							if (student)
								val = student.other_education
								val = val.gsub("'") { |apos| "\\'" }
								sql = "select distinct students.id,name,sort_name from `students` inner join attended_years on students.id = `attended_years`.`student_id` where other_education='#{val}' and school='#{type}'"
								match = ActiveRecord::Base.connection.execute(sql)
								match.each { |education|
									students.push({ :id => education[0], 'name' => education[1], 'sort_name' => education[2] })
								}
							end
							if students.length > 0
								selection = student.other_education
								list = make_three_columns({ :recs => students, :column => 'sort_name', :show_column => 'name', :alt_text => method(:duplicate_student_format) })
								total = students.length
							else
								selection = ""
								list = [[], [], []]
							end
						end

					elsif subtype == 'political_office'
						if selection_id == nil
							sql = "select distinct government_posts.which,government_posts.title,government_posts.id from `government_posts` inner join attended_years on `government_posts`.`student_id` = `attended_years`.`student_id` where school='#{type}' group by government_posts.which,government_posts.title"
							match = ActiveRecord::Base.connection.execute(sql)
							offices = []
							match.each { |office|
								offices.push({ :id => office[2], :which => office[0], :office => office[1] })
							}
							sql = "select distinct government_posts.student_id from `government_posts` inner join attended_years on `government_posts`.`student_id` = `attended_years`.`student_id` where which='$$$SORT_COLUMN$$$' and title='$$$COLUMN$$$' and school='#{type}'"
							list = make_three_columns_sorted({ :recs => offices, :column => :office, :sort_column => :which, :total_sql => sql })
						else
							post = GovernmentPost.find_by_id(selection_id)
							students = []
							if (post)
								sql = "select students.id,name,sort_name from `students` inner join attended_years on students.id = `attended_years`.`student_id` inner join government_posts on students.id = `government_posts`.`student_id` where which='#{post.which}' and title='#{post.title.gsub("'") { |apos| "\\'" }}' and school='#{type}' group by students.id"
								match = ActiveRecord::Base.connection.execute(sql)
								match.each { |student|
									students.push({ :id => student[0], 'name' => student[1], 'sort_name' => student[2] })
								}
							end
							if students.length > 0
								selection = "#{post.which}: #{post.title}"
								list = make_three_columns({ :recs => students, :column => 'sort_name', :show_column => 'name', :alt_text => method(:duplicate_student_format) })
								total = students.length
							else
								selection = ""
								list = [[], [], []]
							end
						end

				elsif subtype == 'hometown'
					if selection_id == nil
						selection = "United States"
						sub_selection = "CT"
					else
						arr = selection_id.split(':')
						if arr.length == 1
							selection = arr[0]
							sub_selection = selection == 'United States' ? "CT" : ""
						else
							selection = arr[0]
							sub_selection = arr[1]
							sub_selection = "" if sub_selection == "[Unknown]"
						end
					end

					# This gets a list of all the unique home_states for students in a particular school
					students = Student.all()
					# weed out students from the other school
					students.delete_if {|student|
						student.fill_record()
						!student.school.include?(type) || student.home_country == nil || student.home_country.length == 0
					}
					# get rid of duplicates
					students = students.sort { |a,b|
						if a.home_country == b.home_country
							astate = a.home_state == nil ? "" : a.home_state
							bstate = b.home_state == nil ? "" : b.home_state
							astate <=> bstate
						else
							a.home_country <=> b.home_country
						end
					}
					last_state = "$$$$$$$$$$"
					students.delete_if {|student|
						temp = last_state
						last_state = "#{student['home_country']}:#{student['home_state']}"
						"#{student['home_country']}:#{student['home_state']}" == temp
					}

					sub_menu = {}
					students.each { |student|
						if sub_menu[student['home_country']] == nil
							sub_menu[student['home_country']] = []
						end
						state = student['home_state'] == nil || student['home_state'].length == 0 ? "[Unknown]" : student['home_state']
						sub_menu[student['home_country']].push(state)
					}
					if sub_selection == ""
						sub_selection = sub_menu[selection] ? sub_menu[selection][0] : "[Unknown]"
					end

					state = sub_selection == "[Unknown]" ? "" : sub_selection
					students = Student.find_all_by_home_country_and_home_state(selection, state)
					students.delete_if {|student|
						student.fill_record()
						!student.school.include?(type)
					}
					if selection == 'United States'
						stus = Student.find_all_by_home_country(selection)
						stus.delete_if {|student|
							student.fill_record()
							!student.school.include?(type)
						}
						country_total = stus.length
					end
					list = make_three_columns_sorted({ :recs => students, :column => 'sort_name', :sort_column => 'home_town', :show_column => 'name', :alt_text_proc => method(:duplicate_student_format), :header_totals => true })
					total = students.length

				elsif subtype == 'residences'
					if selection_id == nil
						selection = "United States"
						sub_selection = "CT"
					else
						arr = selection_id.split(':')
						if arr.length == 1
							selection = arr[0]
							sub_selection = selection == 'United States' ? "CT" : ""
						else
							selection = arr[0]
							sub_selection = arr[1]
							sub_selection = "" if sub_selection == "[Unknown]"
						end
					end
					residences = Residence.all()
					# weed out students from the other school
					residences.delete_if {|residence|
						sr = StudentResidence.find_all_by_residence_id(residence.id)
						found = false
						sr.each { |r|
							student = Student.find(r.student_id)
							student.fill_record()
							found = true if student.school.include?(type)
						}
						!found	# this is the return value for delete_if
					}
					# get rid of duplicates
					residences = residences.sort { |a,b|
						if a.country == b.country
							astate = a.state == nil ? "" : a.state
							bstate = b.state == nil ? "" : b.state
							astate <=> bstate
						else
							a.country <=> b.country
						end
					}
					last_state = "$$$$$$$$$$"
					residences.delete_if {|residence|
						temp = last_state
						last_state = "#{residence['country']}:#{residence['state']}"
						"#{residence['country']}:#{residence['state']}" == temp
					}

					sub_menu = {}
					residences.each { |residence|
						if sub_menu[residence['country']] == nil
							sub_menu[residence['country']] = []
						end
						state = residence['state'] == nil || residence['state'].length == 0 ? "[Unknown]" : residence['state']
						sub_menu[residence['country']].push(state)
					}
					if sub_selection == ""
						sub_selection = sub_menu[selection] ? sub_menu[selection][0] : "[Unknown]"
					end

					state = sub_selection == "[Unknown]" ? "" : sub_selection
					residences = Residence.find_all_by_country_and_state(selection, state)
					students = []
					residences.each { |residence|
						sr = StudentResidence.find_all_by_residence_id(residence.id)
						sr.each { |rec|
							student = Student.find_by_id(rec.student_id)
							student.fill_record()
							student.home_town = residence.town	# hack to make the make_three_columns_sorted method work. Just don't save the record!
							students.push(student) if student.school.include?(type)
						}
					}
					if selection == 'United States'
						residences = Residence.find_all_by_country(selection)
						stus = {}
						residences.each { |residence|
							sr = StudentResidence.find_all_by_residence_id(residence.id)
							sr.each { |rec|
								student = Student.find_by_id(rec.student_id)
								student.fill_record()
								stus[student.id] = 'true' if student.school.include?(type)
							}
						}
						country_total = stus.length
					end
					list = make_three_columns_sorted({ :recs => students, :column => 'sort_name', :sort_column => 'home_town', :show_column => 'name', :alt_text_proc => method(:duplicate_student_format), :header_totals => true })
					total = students.length
#					if selection_id == nil
#						states = Residence.all(:group => 'state')
#						states.delete_if {|place|
#							residences = Residence.find_all_by_state(place.state)
#							found_one = false
#							residences.each { |place2|
#								place2.students.each {|student|
#									student.fill_record()
#									found_one = true if student.school.include?(type)
#								}
#							}
#							found_one == false
#						}
#						list = make_three_columns_sorted(states, 'state', 'country', 'state')
#					else
#						residence = Residence.find_by_id(selection_id)
#						if residence != nil
#							selection = residence.state
#							residences = Residence.find_all_by_state(selection)
#							residences = residences.sort {|a,b| a.town <=> b.town }
#							student_arr = []
#							residences.each { |place|
#								place.students.delete_if {|student|
#									student.fill_record()
#									!student.school.include?(type)
#								}
#								student_arr.push({ :label => place.town, :arr => place.students }) if place.students.length > 0
#							}
#							list = make_three_columns_arr({ :recs => student_arr, :column => 'sort_name', :show_column => 'name', :alt_text => method(:duplicate_student_format) })
#						else
#							selection = ""
#							list = [[], [], []]
#						end
#					end

				elsif subtype == 'name'
					selection_id = 'A' if selection_id == nil
					arr = selection_id.split('-')
					date_recs = AttendedYear.all(:group => 'student_id', :conditions => ["year >= ? AND year <= ? AND school = ?", arr[0], arr[1], type])
					students = []
					search = arr[0]+ '%'
					students += Student.all(:conditions => [ "sort_name LIKE ?", search])
					if arr.length > 1
						search = arr[1]+ '%'
						students += Student.all(:conditions => [ "sort_name LIKE ?", search])
					end
					students.delete_if {|student|
						student.fill_record()
						!student.school.include?(type)
					}
					selection = selection_id
					list = make_three_columns({ :recs => students, :column => 'sort_name', :show_column => 'name', :alt_text => method(:duplicate_student_format) })

				elsif subtype == 'dates'
					selection_id = '1774-1794' if selection_id == nil
					arr = selection_id.split('-')
					date_recs = AttendedYear.all(:group => 'student_id', :conditions => ["year >= ? AND year <= ? AND school = ?", arr[0], arr[1], type])
					students = []
					date_recs.each {|date|
						students.push(Student.find(date.student_id))
					}
					selection = selection_id
					list = make_three_columns({ :recs => students, :column => 'sort_name', :show_column => 'name', :alt_text => method(:duplicate_student_format) })
				end
			else	# browse by material
				if subtype == 'category'
					if selection_id == nil
						categories = Category.all()
						list = make_three_columns({ :recs => categories, :column => 'title' })
					else
						rec = Category.find_by_id(selection_id)
						if rec != nil
							materials = rec.materials
							selection = rec.title
							if selection.include?('People')
								materials.each {|material|
									material['sort_name'] = Student.make_sort_name(material.original_name)
								}
								list = make_three_columns({ :recs => materials, :column => 'sort_name', :show_column => 'name', :alt_text => method(:duplicate_material_format) })
							else
								list = make_three_columns({ :recs => materials, :column => 'name', :alt_text => method(:duplicate_material_format) })
							end
						else
							selection = ""
							list = [[], [], []]
						end
					end

				elsif subtype == 'dates'
					selection_id = '1774-1794' if selection_id == nil
					arr = selection_id.split('-')
					first = arr[0].to_i
					last = arr[1].to_i
					materials = Material.all()
					materials = materials.delete_if { |material|
						VagueDate.is_between(material.material_date, first, last) == false
					}
					selection = selection_id
					list = make_three_columns({ :recs => materials, :column => 'name', :alt_text => method(:duplicate_material_format) })

				elsif subtype == 'repository'
					if selection_id == nil
						materials = Material.all(:group => 'held_at')
						list = make_three_columns({ :recs => materials, :column => 'held_at', :alt_text => method(:duplicate_material_format) })
					else
						rec = Material.find_by_id(selection_id)
						if rec != nil
							materials = Material.find_all_by_held_at(rec.held_at)
							selection = rec.held_at
							list = make_three_columns({ :recs => materials, :column => 'name', :alt_text => method(:duplicate_material_format) })
						else
							selection = ""
							list = [[], [], []]
						end
					end
				end
			end
			{ :selection => selection, :list => list, :sub_menu => sub_menu, :sub_selection => sub_selection, :total => total, :country_total => country_total }	# This is what is stored in the cache and returned.
		}
	end

	private
	def self.duplicate_material_format(rec)
		str = rec[:'medium']
		if rec[:author] && rec[:author].length > 0
			author = rec[:author].split(' (')
			str += " by #{author[0]}"
		end
		return str
	end

	def self.duplicate_student_format(rec)
		born = rec[:born]
		died = rec[:died]
		if born && died
			return "#{born}-#{died}"
		elsif born && !died
			return "Born: #{born}"
		elsif !born && died
			return "Died: #{died}"
		else
			return "Unknown birthday"
		end
	end

	def self.collapse_dups(arr2)
		# Get rid of duplicate items by collapsing them into a single item, which has a :options, which is an array of { :label, :id }
		arr = []
		arr2.each {|rec|
			last = arr.last
			if last && last[:label] == rec[:label]
				if rec[:alt_text] && rec[:alt_text].length > 0
					rec[:label] = rec[:alt_text]
				end
				if last[:options]
					last[:options].push(rec)
				else
					last[:options] = [ last.clone, rec ]
					if last[:options][0][:alt_text] && last[:options][0][:alt_text].length > 0
						last[:options][0][:label] = last[:options][0][:alt_text]
					end
				end
			else
				arr.push(rec)
			end
		}
		return arr
	end

	def self.make_three_columns(options)
		recs = options[:recs]
		column = options[:column]
		show_column = options[:show_column] ? options[:show_column] : column
		alt_text_proc = options[:alt_text]
		total_sql = options[:total_sql]
		num_cols = options[:num_cols] || 3
		arr = recs.sort { |a,b| a[column] <=> b[column] }
		arr2 = []
		arr.each {|rec|
			str = alt_text_proc ? alt_text_proc.call(rec) : ''
			label =  rec[show_column]
			if total_sql
				sql = total_sql.gsub("$$$ID$$$", rec[:id].to_s)
				val = rec[column].to_s
				val = val.gsub("'") { |apos| "\\\\'" }
				sql = sql.gsub("$$$COLUMN$$$", val)
				match = ActiveRecord::Base.connection.execute(sql)
				label = "#{label} (#{match.count})"
			end
			arr2.push({:label => label, :id => rec[:id], :alt_text => str })
		}
		return columnize(arr2, num_cols)
	end

	def self.make_three_columns_arr(options)
		recs_arr = options[:recs]
		column = options[:column]
		show_column = options[:show_column] ? options[:show_column] : column
		alt_text_proc = options[:alt_text]
		num_cols = options[:num_cols] || 3
		arr2 = []
		recs_arr.each {|recs|
			if recs[:label] && recs[:label].length > 0
				arr2.push({ :label => '' })
				arr2.push({ :label => recs[:label] })
			end
			recs[:arr].each {|rec|
				str = alt_text_proc ? alt_text_proc.call(rec) : ''
				arr2.push({:label => rec[show_column], :id => rec.id, :alt_text => str })
			}
		}
		return columnize(arr2, num_cols)
	end

	def self.columnize(arr, num_cols)
		# 1-10 items, in one column
		# 11-20 items in two columns, but with the first column still having 10 items in it
		# 21-30 items in two full columns of 10 and then fill in the third.
		# 31+ items in three equal columns
		arr = collapse_dups(arr)

		ret = [[], [], []]
		if arr.length <= num_cols*10
			col = 0
			arr.each {|item|
				col += 1 if ret[col].length > 10
				ret[col].push(item)
			}
		else
			height = (arr.length / (num_cols* 1.0)).ceil
			col = 0
			count = 0
			arr.each {|item|
				ret[col].push(item)
				count += 1
				if count >= height
					count = 0
					col += 1
				end
			}
		end
		return ret
	end

	def self.make_three_columns_sorted(options)
		recs = options[:recs]
		column = options[:column]
		sort_column = options[:sort_column]
		show_column = options[:show_column] || column
		alt_text_proc = options[:alt_text_proc]
		header_totals = options[:header_totals]
		total_sql = options[:total_sql]
		num_cols = options[:num_cols] || 3

		arr = recs.sort { |a,b|
			if a[sort_column] == b[sort_column]
				a[column] <=> b[column]
			else
				a[sort_column] <=> b[sort_column]
			end
		}

		arr2 = []
		curr_value = 'xxxdoesntmatchxxx'
		heading_index = -1
		total = 0
		arr.each {|rec|
			if rec[sort_column] != curr_value
				if rec[sort_column] && rec[sort_column].length > 0
					arr2.push({ :label => '' }) if arr2.length > 0
					arr2.push({ :label => rec[sort_column] })
					if heading_index >= 0
						arr2[heading_index][:label] = header_totals ? "#{arr2[heading_index][:label]} (#{total})" : arr2[heading_index][:label]
					end
					heading_index = arr2.length-1
					total = 0
				end
				curr_value = rec[sort_column]
			end
			str = alt_text_proc ? alt_text_proc.call(rec) : ''
			label =  rec[show_column]
			if total_sql
				sql = total_sql.gsub("$$$ID$$$", rec[:id].to_s)
				val = rec[column].to_s
				val = val.gsub("'") { |apos| "\\\\'" }
				sql = sql.gsub("$$$COLUMN$$$", val)
				val = rec[sort_column].to_s
				val = val.gsub("'") { |apos| "\\\\'" }
				sql = sql.gsub("$$$SORT_COLUMN$$$", val)
				match = ActiveRecord::Base.connection.execute(sql)
				label = "#{label} (#{match.count})"
			end
			arr2.push({:label => label, :id => rec[:id], :alt_text => str })
			total += 1
		}
		if heading_index >= 0
			arr2[heading_index][:label] = header_totals ? "#{arr2[heading_index][:label]} (#{total})" : arr2[heading_index][:label]
		end

		return columnize(arr2, num_cols)
	end
end
