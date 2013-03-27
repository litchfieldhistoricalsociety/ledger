##########################################################################
# Copyright 2009 Applied Research in Patacriticism and the University of Virginia
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##########################################################################

namespace :import do
	require 'csv'
	#require "faster_csv"

	def each_row(fname, max_recs = nil)
		max_recs = 99999 if max_recs == nil
		max_recs = max_recs.to_i
		# This reads the file as CSV and calls the block passed to it with each row. The row is returned as a hash with the column name as the key.
		# Therefore, we don't have to worry about the column positions outside of this function.
		is_first = true
		col_names = []
		count = 0
		CSV.foreach(fname, :encoding => 'u') do |row|
		#FasterCSV.foreach(fname, :encoding => 'u') do |row|
			if is_first
				row.each {|col|
					col_names.push("#{col}")
				}
				is_first = false
			else
				h = {}
				col_names.each_with_index { |col, i|
					h[col.strip().gsub(/\s+/, ' ')] = "#{row[i]}".gsub(/\s+/, ' ')
				}
				yield(h, count)
				count += 1
				return if count >= max_recs
			end
		end
	end

	def parse_year_string(str, name)
		res = AttendedYear.parse_year_string(str)
		return res if res
		puts "unrecognized year in Years attended: \"#{str}\" (#{name})"
		return { :comment => '', :years => [] }
	end

	def parse_later_residences(town)
		# each residence is separated by a semi colon, and there should be two slashes separating the fields in each residence.
		town = town.gsub(/\s+/, ' ') if town
		residences = town.split(';')
		ret = []
		residences.each {|residence|
			arr = residence.split('/')
			if arr.length == 1
				ret.push({:town => '', :state => residence.strip().chomp(',').strip(), :country => 'United States' })
			elsif arr.length == 2
				ret.push({:town => arr[0].strip().chomp(',').strip(), :state => arr[1].strip().chomp(',').strip(), :country => 'United States' })
			else
				country = arr[2].strip().chomp(',').strip()
				country = "United States" if country == "Unied States"
				country = "United States" if country == "Unitd States"
				ret.push({:town => arr[0].strip().chomp(',').strip(), :state => arr[1].strip().chomp(',').strip(), :country => country })
			end
		}
		return ret
	end

	def get_or_create_student(name)
		# TODO-PER: some people have the same name, so that's not a good key
		# if the student has a stub record, then overwrite it. Otherwise create a new one.
		rec = Student.find_by_name_and_is_stub(name, true)
		if rec == nil
			return Student.new
		else
			return rec
		end
	end

	def parse_hometown_list(hometown_list)
		return [] if hometown_list == nil || hometown_list.length == 0
		# see if there are two in the list
		arr = hometown_list.split("2 -")
		if arr.length == 1	# only one in the list
			return [ parse_hometown(hometown_list)]
		end
		# get the first one
		list = []
		home = arr[0].gsub('1 -', '')
		list.push(parse_hometown(home))
		# see if there are three in the list
		arr = arr[1].split("3 -")
		if arr.length == 1	# only two
			list.push(parse_hometown(arr[0]))
			return list
		end
		# get the second one
		list.push(parse_hometown(arr[0]))
		# get the third one
		list.push(parse_hometown(arr[1]))
		return list
	end

	def parse_hometown(hometown)
		ret = {}
		if hometown && hometown.length > 0
			hometown = hometown.split(';')[0] # TODO-PER: Some of the hometowns have multiples, but the data doesn't support that.
			hometown = hometown.split(' or ')[0] # TODO-PER: Some of the hometowns have multiples, but the data doesn't support that.
			home = hometown.split('/')
			if home.length >= 2
				ret[:home_town] = home[0].strip()
				ret[:home_state] = home[1].strip()
				ret[:home_country] = home.length > 2 ? home[2].strip() : 'United States'
				ret[:home_country] = "United States" if ret[:home_country] == 'Unied States'
				ret[:home_country] = "United States" if ret[:home_country] == 'United State'
			end
		end
		return ret
	end

	def add_family_members(row)
		name = make_name(row['Primary Name'], "#{row['Last Name']}#{row['Maiden Name']}")	# Either Last or Maiden is present, use whichever.
		name = name.gsub(/\s+/, ' ')

		name = name.sub(/(Miss\s+)|(Mr\.?\s+)|(Mrs\.?\s+)|(Ms\.?\s+)/, '')
		if name.length < 2 || name.index('nknown') != nil
			puts "Skipping creation of student: #{name}"
			return nil
		end
		#rec = Student.find_by_name(name)

		family_members = row["Family Members Who Attended LFA or LLS"]
		family_members = row["Family Members Who  Attended LFA or LLS"] if !family_members
		if family_members && family_members.length > 0 && family_members.strip().length > 0
			relations = collect_family_members(family_members)
			if relations
				relation_data = { 'brother' => { :type => 'sibling', :gender => 'M' },
					'sister' => { :type => 'sibling', :gender => 'F' },
					'sibling' => { :type => 'sibling', :gender => nil },
					'daughter' => { :type => 'child', :gender => 'F' },
					'son' => { :type => 'child', :gender => 'M' },
					'children' => { :type => 'child', :gender => nil },
					'father' => { :type => 'parent', :gender => 'M' },
					'mother' => { :type => 'parent', :gender => 'F' }
				}
				relations.each {|relation|
					data = relation_data[relation[:relation]]
					if data != nil
						relation[:names].each { |name2|
							name2.strip!
#							puts "Rel: #{name} <= #{name2} (#{data[:type]}/#{data[:gender]})"
#							Relation.create_relationship(data[:type], { :name => name2, :gender => data[:gender] }, rec)
							should_create = Relation.analyze_relationship(data[:type], { :name => name2, :gender => data[:gender] }, name)
							if should_create
								Relation.create_relationship(data[:type], { :name => name2, :gender => data[:gender] }, Student.find_by_original_name(name))
							end
						}
					else
						puts "ERR: unknown relationship (#{name}): " + relation[:relation]
					end
				}
			else
				puts "ERR:" + family_members
			end
		end
	end

	def add_student(row, children_list)
		# Fields not used in LLS:
		#	Image and Location
		#	Archival Material and Location
		#	Artifacts and Location
		#	Federal Governmental Position Years
		#	State Governmental Position Years
		#	Local Governmental Position Years

		# Fields not used in LFA:
		# Image and Location
		# Archival Material and Location
		# Needlework/Embroidery
		# Artifacts and Location
		# Secondary Sources (second copy)
		# Spouse's Occupation
		# Father's Occupation

		# Fields not used in non-student:
		# Connection to LFA or LLS
		# Image and Location
		# Archival Material and Location
		# Artifacts and Location

		name = make_name(row['Primary Name'], "#{row['Last Name']}#{row['Maiden Name']}")	# Either Last or Maiden is present, use whichever.
		name = name.gsub(/\s+/, ' ')

		name = name.sub(/(Miss\s+)|(Mr\.?\s+)|(Mrs\.?\s+)|(Ms\.?\s+)/, '')
		if name.length < 2 || name.index('nknown') != nil
			puts "Skipping creation of student: #{name}"
			return nil
		end
		both_schools = [ 'John Bissell, Jr.', 'William Whiting Boardman', 'Buel Hunt Deming', 'George Gould', 'James Reeve Gould', 'Samuel Penney, Jr.', 'Henry Seymour', 'Origen Storrs Seymour', 'Lewis Bartholomew Woodruff' ]
		rec = nil
		if both_schools.index(name)  != nil
			rec = Student.find_by_name_and_is_stub(name, false)
		end
		if rec == nil
			rec = get_or_create_student(name)

			rec.name = name
			rec.sort_name = Student.make_sort_name(name)
			rec.other_name = row['Other Names']
			rec.gender = row['Gender'] == 'Female' ? 'F' : 'M'
			rec.room_and_board = row['Room and Board']
			hometown = parse_hometown(row['Hometown'])
			rec.home_town = hometown[:home_town] if hometown[:home_town]
			rec.home_state = hometown[:home_state] if hometown[:home_state]
			rec.home_country = hometown[:home_country] if hometown[:home_country]
			rec.other_education = row['Other Education']
			rec.admitted_to_bar = row['Admitted to Bar']
			rec.training_with_other_lawyers = row['Training with other Lawyers']
			rec.born = normalize_date(row['Year Born'], "#{name} (born)")
			rec.died = normalize_date(row['Year Died'], "#{name} (died)")
			rec.federal_committees = row['Federal Committees Served On']
			rec.state_committees = row['State Committees Served On']
			rec.biographical_notes = row['Biographical Information']
			if rec.biographical_notes && rec.biographical_notes.length > 5100
				puts "Truncated biographical_notes (#{name}:#{rec.biographical_notes.length})"
				rec.biographical_notes = rec.biographical_notes[0..5100]
			end
			rec.citation_of_attendance = row['Citation of Attendance']
			rec.secondary_sources = row['Secondary Sources']
			rec.additional_notes = row['Additional Notes']
			rec.private_notes = row['Private Notes']
			rec.benevolent_and_charitable_organizations = row['Benevolent and Charitable Organizations']
			rec.is_stub = false
			if !rec.save
				puts "ERROR: #{rec.name}"
				rec.errors.each do |attr, error|
					puts "#{attr.to_s.gsub('_', ' ').capitalize()}: #{error}"
				end
			end

			# relationships
			spouse_name = row["Spouse's Name"]
			marriage_dates = row['Marriage Date']	# there should be the same number of marriage dates as spouse names
			marriage_dates = marriage_dates.sub(/(\d)\s\s\s\s\s+(\d)\s*-/, "\1; \2 -")	# add a missing semicolon
			spouse_arr = spouse_name.split(';')
			dates_arr = marriage_dates.split(';')
			if spouse_arr.length < dates_arr.length
				if dates_arr.length == 1
					spouse_arr.push("Unknown")
				else
					puts "spouses and dates don't match: \"#{spouse_name}\" and \"#{marriage_dates}\""
				end
			else
				dates = []
				spouse_arr.length.times { dates.push('')}
				dates_arr.each { |d|
					arr2 = d.split(/\s*-\s*/)
					if arr2.length == 1 && spouse_arr.length == 1
						dates[0] = d
					elsif arr2.length != 2
						puts "Marriage date format problem: #{d}"
					else
						dates[arr2[0].to_i - 1] = arr2[1]
					end
				}

				spouse_home_town_arr = parse_hometown_list(row["Spouse's Hometown"])
				spouse_arr.each_with_index { |spouse, i|
					spouse = spouse.gsub(/\d\s*-/, '')
					spouse = spouse.strip()
					if spouse.length > 0
						spouse_education = row["Spouse's Education"]
						#spouse_home_state = row["Spouse's Hometown - State"]
						#spouse_occupation = row["Spouse's Occupation"]
						if spouse_home_town_arr.length > i
							spouse_home_town = spouse_home_town_arr[i]
						else
							spouse_home_town = { :home_town => nil, :home_state => nil, :home_country => nil }
						end
						if dates[i].strip() == 'Unknown' || dates[i].strip() == 'unknown' || dates[i].strip() == 'Unkknown'
							date = nil
						else
							date = normalize_date(dates[i], "#{name} (marriage date)")
						end
						Marriage.create_marriage(rec, { :name => spouse, :other_education => spouse_education, :home_town => spouse_home_town[:home_town], :home_state => spouse_home_town[:home_state], :home_country => spouse_home_town[:home_country]}, date)
					end
				}
			end
			father_name = row["Father's Name"]
			father_born = normalize_date(row["Father's Birth Date"], "#{name} (father born)")
			father_died = normalize_date(row["Father's Death Date"], "#{name} (father died)")
			father_education = row["Father's Education"]
			dates = row["Father's Birth and Death Dates"]
			if dates != nil
				dates = dates.split('-')
				if dates == nil || dates.length == 0
					dates = ['', '']
				else
					dates[1] = '' if dates.length < 2
					dates[0] = dates[0].sub('b.', '')
					if dates[0].include?('d.')
						dates[1] = dates[0].sub('d.', '')
						dates[0] = ''
					end
				end
				father_born = dates[0]
				father_died = dates[1]
			end
			
			father_occupation = row["Father's Occupation"]
			Relation.create_relationship('parent', { :name => father_name, :born => father_born, :died => father_died, :other_education => father_education, :gender => 'M' }, rec) if father_name.length > 0
			mother_name = row["Mother's Name"]
			mother_born = normalize_date(row["Mother's Birth Date"], "#{name} (mother born)")
			mother_died = normalize_date(row["Mother's Death Date"], "#{name} (mother died)")
			dates = row["Mother's Birth and Death Dates"]
			if dates != nil
				dates = dates.split('-')
				if dates == nil || dates.length == 0
					dates = ['', '']
				else
					dates[1] = '' if dates.length < 2
					dates[0] = dates[0].sub('b.', '')
					if dates[0].include?('d.')
						dates[1] = dates[0].sub('d.', '')
						dates[0] = ''
					end
				end
				mother_born = dates[0]
				mother_died = dates[1]
			end
			Relation.create_relationship('parent', { :name => mother_name, :born => mother_born, :died => mother_died, :gender => 'F' }, rec) if mother_name.length > 0
			family_members = row["Family Members Who  Attended LFA or LLS"]
			if family_members
				relations = collect_family_members(family_members)
				if relations
					relation_data = { 'brother' => { :type => 'sibling', :gender => 'M' },
						'sister' => { :type => 'sibling', :gender => 'F' },
						'sibling' => { :type => 'sibling', :gender => nil },
						'daughter' => { :type => 'child', :gender => 'F' },
						'son' => { :type => 'child', :gender => 'M' },
						'children' => { :type => 'child', :gender => nil },
						'father' => { :type => 'parent', :gender => 'M' },
						'mother' => { :type => 'parent', :gender => 'F' }
					}
					relations.each {|relation|
						data = relation_data[relation]
						if data != nil
							relation[:names].each { |name2|
								Relation.create_relationship(data[:type], { :name => name2, :gender => data[:gender] }, rec)
							}
						end
					}
				else
					puts "ERR:" + relations
				end
			end


			children = row["Children Who Attended LFA or LLS"]
			if children && children.strip().length > 0
				children = children.split(';')
				children.each {|child|
					child = child.strip()
					# add this if it exists, otherwise just save it for later, in case the record is coming up later.
					test = Student.find_by_name(child)
					if test
						Relation.create_relationship('parent', { :name => rec.name }, test)
					else
						children_list.push({ :parent_name => rec.name, :child_name => child})
					end
				}
			end

			# see if the format is the old style with town and state in different fields
			res_state = row["Later Residence - State"]
			if res_state != nil && res_state.length > 0
				res_town = row["Later Residence - Town"]
				town_arr = res_town.split(';')
				state_arr = res_state.split(';')
				res_arr = []
				town_arr.each_with_index {|town, i|
					res_arr.push("#{town}/#{state_arr[i]}/United States")
				}
				res = res_arr.join(';')
			else
				res = row["Later Residence - Town"]
			end
			later_residences = parse_later_residences(res)
			later_residences.each {|resid|
				home_rec = Residence.first(:conditions => [ 'town = ? AND state = ? AND country = ?', resid[:town], resid[:state], resid[:country]])
				if home_rec == nil
					home_rec = Residence.create(resid)
				end
				StudentResidence.create(:student_id => rec.id, :residence_id => home_rec.id)
			}

			profession = row["Occupation"]
			profession = row["Profession/ Career"] if profession == nil

			professions = profession.split(';')
			professions.each {|job|
				job = job.strip()
				if job.length > 0
					job_rec = Profession.find_by_title(job)
					if job_rec == nil
						job_rec = Profession.create(:title => job)
					end
					StudentProfession.create(:student_id => rec.id, :profession_id => job_rec.id)
				end
			}

			political_party = row["Politcal Party"]
			if political_party
				political_partys = political_party.split(';')
				political_partys.each {|job|
					job = job.strip()
					if job.length > 0
						job_rec = PoliticalParty.find_by_title(job)
						if job_rec == nil
							job_rec = PoliticalParty.create(:title => job)
						end
						StudentPoliticalParty.create(:student_id => rec.id, :political_party_id => job_rec.id)
					end
				}
			end

			govt_pos = row["Federal Governmental Position"]
			create_govt_post(govt_pos, rec.id, 'Federal')
			govt_pos = row["State Governmental Position"]
			create_govt_post(govt_pos, rec.id, 'State')
			govt_pos = row["Local Governmental Position"]
			create_govt_post(govt_pos, rec.id, 'Local')

			other = row["Other Related Objects and Documents"]
			if other && other.strip().length > 0
				arr = other.split(';')
				if arr.length % 2 != 0
					puts "Must be an even number of fields in \"Other Related Objects and Documents\": #{other}"
				end
				num = arr.length / 2
				num = num.floor()
				num.times { |i|
					OffsiteMaterial.create({ :name => arr[i*2], :url => arr[i*2+1], :student_id => rec.id })
				}
			end
		end

		raw_years = row["Years at LLS"]
		school = "LLS"
		if raw_years == nil
			school = "LFA"
			raw_years = row["Years at LFA"]
		end
		if raw_years != nil
			year_hash = parse_year_string(raw_years, name)
			if year_hash[:years].length > 0
				year_hash[:years].each { |y|
					AttendedYear.create({ :student_id => rec.id, :year => y, :school => school, :comment => year_hash[:comment] })
				}
			end
		end
		return rec
	end

	def create_govt_post(govt_pos, student_id, which)
		# govt_pos is formatted: 1 - position (location); etc... with the "1 -" being optional and the location being optional
		if govt_pos
			govt_pos = govt_pos.split(';')
			govt_pos.each {|job|
				job = job.strip()
				if job.length > 0
					arr = job.split('/', 10)
					location = nil
					time_span = nil
					if arr.length == 2
						job = arr[0].strip()
						modifier = arr[1].strip()
					elsif arr.length == 3
						job = arr[0].strip()
						modifier = arr[1].strip()
						location = arr[2].strip()
					elsif arr.length == 4
						job = arr[0].strip()
						modifier = arr[1].strip()
						location = arr[2].strip()
						time_span = arr[3].strip()
					else
						puts "Can't read govt post: #{Student.find(student_id).name}: #{job}"
						job = ''
					end
					GovernmentPost.create({ :student_id => student_id, :which => which, :title => job, :modifier => modifier, :location => location, :time_span => time_span }) if job.length > 0
				end
			}
		end
	end

	def make_name(str1, str2)
		arr = str1.split(' ')
		return str1 if arr.length > 1
		return "#{str1} #{str2}"
	end

	def add_object(row, missing_names, has_main_image_field)
		return nil if row['Title'] == nil || row['Title'].strip().length == 0

		rec = Material.new
		# Unused fields
		# Caption
		# Image Ready for Gibson
		#	Associated Files
		#	Transcription Files

		rec.name = row['Title']
		rec.object_id = row['Object ID#']
		rec.accession_num = row['Accession #']
		rec.url = row['URL']
		#rec.url = rec.url.sub("http://www.litchfieldhistoricalsociety.org", '') if rec.url
		rec.author = row['Author/Creator']
		if rec.author == nil
			rec.author = row['Creator(s)']
		end
		rec.material_date = normalize_date(row['Date'], 0)
		rec.collection = row['Collection']
		rec.held_at = row['Held At']
		rec.associated_place = row["Associated Place"]
		if rec.associated_place == nil
			rec.associated_place = row["Associated Place(s)"]
		end
		rec.medium = row['Medium']
		rec.size = row['Size']
		rec.description = row['Description']
		rec.private_notes = row['Private Notes']
		if !rec.save
			puts "ERROR: #{rec.name}"
			rec.errors.each do |attr, error|
				puts "#{attr.to_s.gsub('_', ' ').capitalize()}: #{error}"
			end
		end

		students = row['Student']
		students = row['Associated People'] if students == nil
		if students && students.length > 0 && students != "Unknown"
			students = students.split(';')
			students.each {|stu|
				stu = stu.strip()
				arr = stu.split('/')
				if arr.length > 0
					relationship = arr.length == 2 ? arr[1] : ''
					stu = arr[0]
					stu_rec = Student.find_by_name(stu)
					if stu_rec == nil
						puts "Can't find student: #{stu}"
						missing_names.push(stu)
						r = Student.create_stub({:name => stu })
						if r == nil
							puts "No name given in relationship field for object #{rec.name}"
						end
					else
						StudentMaterial.create({ :student_id => stu_rec.id, :material_id => rec.id, :relationship => relationship })
						if has_main_image_field && row['Main Image'] == 'Main Image'
							File.open("#{Rails.root}/tmp/main_image.txt", 'a') {|f| f.write("#{stu_rec.id},#{rec.id}\n") }
						end
					end
				end
			}
		end

#		assoc_files = row['Associated Files']
#		transcription_files = row['Transcription Files']

		category = row["Category"]
		if category
			categories = category.split(';')
			categories.each {|cat|
				cat = cat.strip()
				cat_rec = Category.find_by_title(cat)
				if cat_rec == nil
					cat_rec = Category.create(:title => cat)
				end
				MaterialCategory.create(:material_id => rec.id, :category_id => cat_rec.id)
			}
		end
		
		return rec
	end

	def normalize_date(str, count = nil)
		return nil if str == nil
		#get rid of unusual items
#		str = str.sub("listed on find a grave and earlier label", '')
#		str = str.sub("(in Austinburg, OH)", '')
#		str = str.sub(" (or 1811 according to his tombstone)", "/1811")
		str = str.sub("on ", '')
		str = str.sub(/[Ss]o?metime/, '')
		str = str.sub("18662", "1862")
		str = str.sub("Unknown, but most likely some time in the", '')
#		str = str.sub("____ or ", '')
		str = str.sub("February, 10", "February 10,")
		str = str.sub("(or 13)", '/13')
		str = str.sub("??1893", "??/1893")
		str = str.sub("Aug. 9", "Aug 9,")
		str = str.sub(/[Pp]re-/, 'pre ')
		str = str.sub("25-Mar-01", "March 25, 1801")
#		str = str.sub('July 15,1 1853', 'July 15, 1853')
		str = str.sub('August 31.', 'August 31,')
		str = str.sub('August 9.', 'August 9,')
		str = str.sub('August6', 'August 6')
		str = str.sub("November29", "November 29")
#		str = str.sub('Mar-10', 'March 10, 1800')
		str = str.sub('12-Oct-00', 'October 12, 1800')
#		str = str.sub('28-Sep', 'September 20, 1800')
		str = str.sub('9-Jun-09', 'June 9, 1809')
		str = str.sub('August 2 1805', 'August 2, 1805')
		str = str.sub('November 24 1858', 'November 24, 1858')
		str = str.sub('ca1', 'ca 1')
		str = str.sub('early 19th century', '1800-1820')
		str = str.sub('4-Dec-24', 'December 4, 1824')
		str = str.sub('28m ', '28, ')
		str = str.sub('c.a ', 'ca. ')
		str = str.sub('1895or', '1895 or')

		# misspellings of months
		str = str.sub('Jamuary', 'January')
		str = str.sub('Januayr', 'January')
		str = str.sub('Januaary', 'January')
		str = str.sub('Feburary', 'February')
		str = str.sub('Aprill', 'April')
		str = str.sub('Aril', 'April')
		str = str.sub('Mary', 'May')
		str = str.sub('may', 'May')
		str = str.sub('My', 'May')
		str = str.sub('Jume', 'June')
		str = str.sub('Jue', 'June')
		str = str.sub('Juna', 'June')
		str = str.sub('Spt', 'September')
		str = str.sub('Setember', 'September')
		str = str.sub('Septmber', 'September')
		str = str.sub('Sept.', 'September')
		str = str.sub('Sepember', 'September')
		str = str.sub('Sptmber', 'September')
		str = str.sub('Sptember', 'September')
		str = str.sub('Septmeber', 'September')
		str = str.sub('october', 'October')
		str = str.sub('Nvembr', 'November')
		str = str.sub('Novembr', 'November')
		str = str.sub('Noveber', 'November')
		str = str.sub('Nvember', 'November')
		str = str.sub('Novemeber', 'November')
		str = str.sub('Decmber', 'December')
		str = str.sub('Decenber', 'December')
		str = str.sub('Decembe', 'December')
		str = str.sub('Decmeber', 'December')
		str = str.sub('Decemberr', 'December')
		str = str.sub('Dcember', 'December')
		str = str.sub('Decemeber', 'December')
		str = str.strip()
		return nil if str.length == 0

		vd = VagueDate.factory(str)
#		if vd.kind_of?(VagueDate)
#			puts "    #{count}. '#{str}' = '#{vd.to_s}'"
#		elsif vd == nil
#			puts "    #{count}. '#{str}' = Unknown"
#		end
		return vd.to_s if vd != nil && vd.kind_of?(VagueDate)

		str = "'#{str}'"
		str = "#{count}. #{str}" if count
		puts "#{str} -- #{vd}"
		return nil
	end

	def add_occupation_columns(fname, max_recs)
		puts ""
		change_count = 0
		ignore_count = 0
		error_count = 0
		each_row(fname, max_recs) { |row, count|
#			if (count % 100) == 0
#				print "\n#{count}: "
#			elsif (count % 10) == 0
#				putc "+"
#			else
#				putc "." if (count % 10) != 0
#			end

			name = make_name(row['Primary Name'], "#{row['Last Name']}#{row['Maiden Name']}")	# Either Last or Maiden is present, use whichever.
			name = name.gsub(/\s+/, ' ')
			name = name.sub(/(Miss\s+)|(Mr\.?\s+)|(Mrs\.?\s+)|(Ms\.?\s+)/, '')
			students = Student.find_all_by_name(name)
			comment = []
			comment.push('STUDENT_NOT_FOUND') if students.length == 0
			comment.push('STUDENT_AMBIGUOUS') if students.length > 1

			fathers_occupation = row["Father's Occupation"]
			if fathers_occupation
				father = nil
				if students.length == 1
					relations = Relation.find_all_by_student2_id_and_relationship(students[0].id, 'parent')
					relations.each {|relation|
						parent = Student.find(relation.student1_id)
						if parent.gender == 'M'
							if father == nil
								father = parent
							else
								comment.push("TWO_FATHERS")
							end
						end
					}
				end
				comment.push("FATHER_NOT_FOUND") if father == nil
				occupations = fathers_occupation.split(';')
				occupations.each {|occupation|
					occupation.strip!
					profession = Profession.find_by_title(occupation)
					comment.push("OCCUPATION_NOT_FOUND") if profession == nil
					if comment.length > 0
						puts "#{name}: Father= #{father.name if father}/\"#{occupation}\" #{comment.join(' ')}"
						puts ""
						error_count += 1
					else
						current_occupations = StudentProfession.find_all_by_student_id_and_profession_id(father.id, profession.id)
						if current_occupations.length > 0
							ignore_count += 1
						else
							StudentProfession.create({ :student_id => father.id, :profession_id => profession.id })
							change_count += 1
						end
					end
					comment.pop if comment.last == "OCCUPATION_NOT_FOUND"
				}
			end

			comment.delete_if { |c| c == "FATHER_NOT_FOUND" }
			spouses_occupation = row["Spouse's Occupation"]
			if spouses_occupation
				spouse = nil
				if students.length == 1
					relations = Relation.find_all_by_student1_id_and_relationship(students[0].id, 'spouse')
					relations.each {|relation|
						if spouse == nil
							spouse = Student.find(relation.student2_id)
						else
							comment.push("TWO_SPOUSES")
						end
					}
					relations = Relation.find_all_by_student2_id_and_relationship(students[0].id, 'spouse')
					relations.each {|relation|
						if spouse == nil
							spouse = Student.find(relation.student1_id)
						else
							comment.push("TWO_SPOUSES")
						end
					}
				end
				comment.push("SPOUSE_NOT_FOUND") if spouse == nil
				occupations = spouses_occupation.split(';')
				occupations.each {|occupation|
					occupation.strip!
					profession = Profession.find_by_title(occupation)
					comment.push("OCCUPATION_NOT_FOUND") if profession == nil
					if comment.length > 0
						puts "#{name}: Spouse= #{spouse.name if spouse}/\"#{occupation}\" #{comment.join(' ')}"
						puts ""
						error_count += 1
					else
						current_occupations = StudentProfession.find_all_by_student_id_and_profession_id(spouse.id, profession.id)
						if current_occupations.length > 0
							ignore_count += 1
						else
							StudentProfession.create({ :student_id => spouse.id, :profession_id => profession.id })
							change_count += 1
						end
					end
					comment.pop if comment.last == "OCCUPATION_NOT_FOUND"
				}
			end
		}
		puts "Number of records changed: #{change_count}; Errors: #{error_count}; Already set count: #{ignore_count}"
		puts ""
	end

	desc "Add occupation fields from the spreadsheet (param: max_recs)"
	task :add_occupations => :environment do
		fname = "#{Rails.root}/lib/tasks/LLS_Student_List.csv"
		puts "~~~~~~~~~~~ Adding occupations from #{fname}..."
		count = add_occupation_columns(fname, ENV['max_recs'])
		fname = "#{Rails.root}/lib/tasks/LFA_Student_List.csv"
		puts "~~~~~~~~~~~ Adding occupations from #{fname}..."
		count = add_occupation_columns(fname, ENV['max_recs'])
		fname = "#{Rails.root}/lib/tasks/non_students.csv"
		puts "~~~~~~~~~~~ Adding occupations from #{fname}..."
		count = add_occupation_columns(fname, ENV['max_recs'])
	end

	desc "Analyze spreadsheets"
	task :analyze => :environment do
		# For analyzing the archive attachments
#		fname = "archives_list.csv"
#		puts "~~~~~~~~~~~ Analyzing #{fname}..."
#		analyze_object_attachments(fname)

		# This is for analyzing the family members field
		fname = "#{Rails.root}/lib/tasks/LLS_Student_List.csv"
		puts "~~~~~~~~~~~ Analyzing #{fname}..."
		count = analyze_student_file(fname, ENV['max_recs'])
		fname = "#{Rails.root}/lib/tasks/LFA_Student_List.csv"
		puts "~~~~~~~~~~~ Analyzing #{fname}..."
		count = analyze_student_file(fname, ENV['max_recs'])
		fname = "#{Rails.root}/lib/tasks/non_students.csv"
		puts "~~~~~~~~~~~ Analyzing #{fname}..."
		count = analyze_student_file(fname, ENV['max_recs'])
		
#		read_object_date("archives_list.csv")
#		read_object_date("objects_with_photo.csv")
#		read_object_date("objects_without_photo.csv")
#		read_object_date("objects_without_student.csv")

	end

	def import_student_file(fname, max_recs, children_list)
		solr = Searcher.new()
		num_processed = 0
		start = Time.now()
		each_row(fname, max_recs) { |row, count|
			if (count % 100) == 0
				print "\n#{count}: "
			elsif (count % 10) == 0
				putc "+"
			else
				putc "." if (count % 10) != 0
			end
			rec = add_student(row, children_list)
			solr.add_object_quick(rec.to_solr()) if rec != nil
			num_processed = count
		}
		puts "\nElapsed: #{(Time.now-start)/60.0} minutes"
		return num_processed
	end

	def import_family_members_field(fname)
		num_processed = 0
		start = Time.now()
		each_row(fname, nil) { |row, count|
			if (count % 100) == 0
				print "\n#{count}: "
			elsif (count % 10) == 0
				putc "+"
			else
				putc "." if (count % 10) != 0
			end
			rec = add_family_members(row)
			num_processed = count
		}
		puts "\nElapsed: #{(Time.now-start)/60.0} minutes"
		return num_processed
	end

	def student_exists(str)
		s2 = str.strip().gsub(/\s+/, ' ')
		stu = Student.find_by_name(s2.strip())
		if stu == nil
			puts "      >> Can't find: #{s2.strip()}"
		else
			print '+'
		end
	end

	def collect_family_members(str)
		# str contains a few different formats.
		if str == nil
			return nil
		end
		# to make the regular expression go quicker, let's just get rid of the dates portion upfront
		dates = "(\\([^;)]+?\\))?"	# anything inside of parens, except a paren or a semi colon
		str = str.gsub(/#{dates}/, '')

		# fix bugs in spreadsheet
		str = str.gsub(/William Thomas Adams\s+Sister/, 'William Thomas Adams; Sister')
		str = str.gsub(/John Marsh Adams\s+Sister/, 'John Marsh Adams; Sister')
		str = str.gsub(/SisterHipah/, 'Sister - Hipah')
		str = str.gsub(/SisterEliza/, 'Sister - Eliza')
		str = str.gsub(/Smith - Laurilla Aleroyla Smith/, 'Sister - Laurilla Aleroyla Smith')

		relationship = "([Nn]ephews|[Dd]aughters|[Ss]iblings|[Bb]rothers|[Ss]isters|[Cc]hildren|[Cc]ousins|[Uu]ncles|[Bb]rother|[Ss]ister|[Uu]ncle|^[Ss]on|[Dd]aughter|[Ff]ather|[Mm]other|[Ss]ibling|[Aa]unt|[Cc]ousin|[Gg]randfather)"
		separators = "(-|;|\\sand\\s)" # "(-|;|\\sand\\s|,(?! Jr\\.))"	# match a hyphen, semicolon, the word 'and', and a comma(unless the comma is followed by Jr.) [?! is a negative lookahead assertion]
		name = "(\\w+\\s*\\w*\\.?\\s*\\w*(,\s*Jr.)*)"
		single_set = str.split(/#{separators}/)
		ret = []
		relation = nil
		names = []
		single_set.each {|item|
			if item.match(/#{relationship}/)
				if relation != nil
					ret.push({ :relation => relation, :names => names })
					names = []
				end
				relation = item.strip().downcase().chomp('s')
			elsif item.strip().length == 0 || item.match(/#{separators}/)
				# just skip these
			elsif item.match(name)
				names.push(item)
			else
				puts "Not matched: [#{item}]"
			end
		}
		if relation != nil
			ret.push({ :relation => relation, :names => names })
		end
		return ret.length == 0 ? nil : ret
	end

	def analyze_object_attachments(fname)
		path = "#{Rails.root}/lib/tasks/#{fname}"
		puts "~~~~~~~~~~~ Analyzing #{path}..."
		start = Time.now()
		paths = get_folder_listing("#{IMAGE_FOLDER }/transcription")
		each_row(path) { |row, count|
			if row['Associated Files'].length > 0 || row['Transcription Files'].length > 0
				puts "#{count}: #{row['Associated Files']} / #{row['Transcription Files']}"
				trans_files = row['Transcription Files'].split(';')
				arr = []
				paths.each { |pth|
					trans_files.each { |f|
						if pth.include?(f.strip())
							arr.push(pth)
						end
					}
				}
				arr.uniq!()
				arr.each { |pth|
					if pth.include?('.pdf')
						puts "#{row['Title']}    #{pth}"
					else
						puts "#{row['Title']}    #{pth}"
					end
				}
			end
		}
		puts "\nElapsed: #{(Time.now-start)/60.0} minutes"
	end

	def analyze_student_file(fname, max_recs)
		num_processed = 0
		start = Time.now()
		each_row(fname, max_recs) { |row, count|
#			other = row["Other Related Objects and Documents"]
#			if other && other.strip().length > 0
#				name = row["Primary Name"]
#				puts "#{count}: #{name}: #{other}"
#			end
			x = row["Federal Governmental Position"]
			if x && x.strip().length > 0
				arr = x.split(';')
				arr.each {|post|
					fields = post.split('/')
					puts "#{count}: FP #{fields.length} #{fields.join(' | ')}"
				}
			end
			x = row["State Governmental Position"]
			if x && x.strip().length > 0
				arr = x.split(';')
				arr.each {|post|
					fields = post.split('/')
					puts "#{count}: SP #{fields.length} #{fields.join(' | ')}"
				}
			end
			x = row["Local Governmental Position"]
			if x && x.strip().length > 0
				arr = x.split(';')
				arr.each {|post|
					fields = post.split('/')
					puts "#{count}: LP #{fields.length} #{fields.join(' | ')}"
				}
			end

#			x = row["Family Members Who Attended LFA or LLS"]
#
#			if x && x.length > 0
#				x = x.strip()
#				if x.length > 0
#					print "#{count} "
#					relations = collect_family_members(x)
#					if relations
#						relations.each {|relation|
#							if relation[:relation] == 'brother' || relation[:relation] == 'sister' || relation[:relation] == 'sibling' || relation[:relation] == 'daughter' || relation[:relation] == 'son' || relation[:relation] == 'father' || relation[:relation] == 'mother'
#								relation[:names].each { |name|
#									student_exists(name)
#								}
#							end
#						}
#					else
#						puts "ERR:" + x
#					end
#				end
#			end

#			puts x.split(';').collect! {|str| str.strip() }.join("\n") if x && x.length > 0
#			x = row["Children Who Attended LFA or LLS"]
#			puts x.split(';').collect! {|str| str.strip() }.join("\n") if x && x.length > 0
			num_processed = count
		}

		puts "\nElapsed: #{(Time.now-start)/60.0} minutes"
		return num_processed
	end

	desc "Import Law School Records (params: max_recs)"
	task :law  => :environment do
		fname = "#{Rails.root}/lib/tasks/LLS_Student_List.csv"
		puts "~~~~~~~~~~~ Importing #{fname}..."
		children_list = []
		count = import_student_file(fname, ENV['max_recs'], children_list)
		puts "Shouldn't have found children list" if children_list.length > 0
		puts "Finished: indexed #{count} students"
	end

	desc "Import Female Academy Records (params: max_recs)"
	task :female  => :environment do
		fname = "#{Rails.root}/lib/tasks/LFA_Student_List.csv"
		puts "~~~~~~~~~~~ Importing #{fname}..."
		children_list = []
		count = import_student_file(fname, ENV['max_recs'], children_list)
		# we deferred finding some children because they weren't created yet. See if they are now.
		children_list.each { |child|
			test = Student.find_by_name(child[:child_name])
			if test
				Relation.create_relationship('parent', { :name => child[:parent_name] }, test)
			else
				puts "Child \"#{child[:child_name]}\" mentioned in \"#{child[:parent_name]}\" that was not found in the database."
			end
		}
		puts "Finished: indexed #{count} students"
	end

	desc "Import LFA Family Members field"
	task :female_family  => :environment do
		fname = "#{Rails.root}/lib/tasks/LFA_Student_List.csv"
		puts "~~~~~~~~~~~ Importing #{fname}..."
		count = import_family_members_field(fname)
		puts "Finished: indexed #{count} students"
	end

	desc "Import Non-student Records (params: max_recs)"
	task :non_students  => :environment do
		fname = "#{Rails.root}/lib/tasks/non_students.csv"
		puts "~~~~~~~~~~~ Importing #{fname}..."
		children_list = []
		count = import_student_file(fname, ENV['max_recs'], children_list)
		puts "Shouldn't have found children list" if children_list.length > 0
		puts "Finished: indexed #{count} students"
	end

	desc "List rows (params: fname)"
	task :list_rows  => :environment do
		start = Time.now()
		f = ENV['fname']
		fname = "#{Rails.root}/lib/tasks/#{f}.csv"
		puts "~~~~~~~~~~~ Listing #{fname}..."
		each_row(fname) { |row, count|
			puts "#{count}: #{row['Title']}"
		}
		puts "\nElapsed: #{(Time.now-start)/60.0} minutes"
	end

	def read_object_csv(solr, missing_names, fname, has_main_image_field)
		path = "#{Rails.root}/lib/tasks/#{fname}"
		puts "~~~~~~~~~~~ Importing #{path}..."
		start = Time.now()
		total = 0
		each_row(path) { |row, count|
			if (count % 100) == 0
				print "\n#{count}: "
			elsif (count % 10) == 0
				putc "+"
			else
				putc "." if (count % 10) != 0
			end
#		contents = csv_import(path)
#		count = 0
#		contents[1].each { |row|
			rec = add_object(row, missing_names, has_main_image_field)
			if rec
				solr.add_object_quick(rec.to_solr())
			else
				puts "#{count}: Empty row skipped"
			end
			count += 1
			total = count
#			puts "Added: #{count}" if count % 100 == 0
		}
		puts "\nElapsed: #{(Time.now-start)/60.0} minutes"
		return total
	end

	def read_object_date(fname)
		path = "#{Rails.root}/lib/tasks/#{fname}"
		puts "~~~~~~~~~~~ Analyzing #{path}..."
		start = Time.now()
		each_row(path) { |row, count|
			if (count % 100) == 0
				print "\n#{count}: "
			elsif (count % 10) == 0
				putc "+"
			else
				putc "." if (count % 10) != 0
			end
			normalize_date(row['Date'], 0)
		}
		puts "\nElapsed: #{(Time.now-start)/60.0} minutes"
	end

	desc "List all government posts"
	task :list_posts => :environment do
		posts = GovernmentPost.find(:all, :conditions => [ "which = ?", 'Federal'], :group => 'title')
		puts "Federal:"
		posts.each {|rec|
			puts rec.title
		}
		posts = GovernmentPost.find(:all, :conditions => [ "which = ?", 'State'], :group => 'title')
		puts "State:"
		posts.each {|rec|
			puts rec.title
		}
		posts = GovernmentPost.find(:all, :conditions => [ "which = ?", 'Local'], :group => 'title')
		puts "Local:"
		posts.each {|rec|
			puts rec.title
		}
	end

	desc "Import objects"
	task :objects  => :environment do
		begin
			File.delete("#{Rails.root}/tmp/main_image.txt")
		rescue
		end
		solr = Searcher.new()
		missing_names = []
		count = 0
		count += read_object_csv(solr, missing_names, "archives_list.csv", false)
		count += read_object_csv(solr, missing_names, "objects_with_photo.csv", true)
		count += read_object_csv(solr, missing_names, "objects_without_photo.csv", true)
		count += read_object_csv(solr, missing_names, "objects_without_student.csv", true)
		#count += read_object_csv(solr, missing_names, "related_objects_no_page.csv", true)
		total_missing = missing_names.length
		missing_names.uniq!()
		missing_names.sort!()
		puts "Missing names: \n#{missing_names.join("\n")}"
		puts "Finished: indexed #{count} objects. #{StudentMaterial.all.count} student connections. #{total_missing} not found."
	end

	require 'find'
	def get_folder_listing(base_path)
		fnames = []
		Find.find(base_path) do |path|
			if FileTest.directory?(path)
				if File.basename(path)[0] == ?.
					Find.prune       # Don't look any further into this directory.
				else
					next
				end
			else
				fnames.push(path) if !path.match(/DS_Store$/)
			end
		end
		return fnames
	end

	desc "Add images to existing objects"
	task :add_images  => :environment do
		str = ''
		File.open("#{Rails.root}/tmp/main_image.txt", "r") { |f|
			str = f.read
		}
		arr = str.split("\n")
		main_image = {}
		arr.each {|rec|
			a2 = rec.split(',')
			main_image[a2[1].to_i] = a2[0].to_i
		}
		MaterialImage.destroy_all()
		Image.destroy_all()
		paths = get_folder_listing("#{IMAGE_FOLDER }/By Individual")
		paths += get_folder_listing("#{IMAGE_FOLDER }/Unknown Student by Categories")
		paths += get_folder_listing("#{IMAGE_FOLDER }/Archives")
		paths = paths.delete_if { |path| path.include?('.pdf') || path.include?('.db') || path.include?('.tif') }
		#puts paths.join("\n")
		materials = Material.all()
		materials.each {|material|
			# for each material, we get the id of that material, then look for an image name that contains that id.
			# All the images that match are loaded in and connected to that object. The images that match are
			# removed from the list so that we can print out all the images that didn't match anything at the end
			# as a check of the system.
			oid = "#{material.object_id}" if material.object_id != nil
			oid = "#{material.accession_num}" if material.accession_num != nil
			matches, paths = paths.partition { |path|
				if oid && oid.length > 2
					path.match(/#{oid}[^\d]/)	# The trick is that the ids can be embedded in each other, so we don't want it to match unless there isn't a number right after it.
				else
					false
				end
			}
			puts "#{material.id}. #{material.name} (#{oid}) Num Imgs: #{matches.length}" if matches.length > 0
			matches.each { |match|
				#puts "    #{match}"
				begin
					img = Image.new
					File.open(match) { |photo_file| img.photo = photo_file }
					img.save
				rescue Exception => e
					puts "Could not save \"#{match}\".\n#{e}\nRetrying..."
					begin
						img = Image.new
						File.open(match) { |photo_file| img.photo = photo_file }
						img.save
					rescue Exception => e
						puts "Failed again"
					end
				end
				MaterialImage.create({ :material_id => material.id, :image_id => img.id })
#				if material.students.length > 0
#					student = material.students[0]
				if main_image[material.id]
					student = Student.find(main_image[material.id])
					student.image_id = img.id
					student.save
#					puts "Student: #{student.name} has image."
				end
			}
		}
		puts "Unused images:"
		puts paths.join("\n")
	end

	desc "Add pdfs to existing objects"
	task :add_pdfs  => :environment do
		path = "#{Rails.root}/lib/tasks/archives_list.csv"
		puts "~~~~~~~~~~~ Adding pdfs from #{path}..."
		MaterialTranscription.destroy_all()
		Transcription.destroy_all()
		start = Time.now()
		paths = get_folder_listing("#{IMAGE_FOLDER }/transcription")
		each_row(path) { |row, count|
			# there are two columns to look at, containing three file types.
			# if it is a .pdf file in either column, then it is a transcription.
			# if it doesn't have a file extention in the Transcription Files, then add .pdf.
			# if it is a .txt file, then it corresponds to a file in the Associated Files side.

			# The Associated Files entry was already scraped because it matches an accession number, so we don't have to save .jpg files
			if row['Transcription Files'].length > 0 || row['Associated Files'].length > 0
				puts "#{count}: #{row['Associated Files']} / #{row['Transcription Files']}"
				trans_files = row['Transcription Files'].split(';')
				assoc_files = row['Associated Files'].split(';')
				arr = []
				# this changes the abbrev. file name into a full path and ignores file names that don't correspond to a file.
				paths.each { |pth|
					trans_files.each { |str|
						af = str.split('/')
						f = af.first.strip()
						if !f.include?('.')
							f += '.pdf'
						end
						t = af.last.strip()
						if pth.include?(f)
							arr.push({ :title => t, :file => pth })
						end
					}
					assoc_files.each { |str|
						# The files are supposed to have a title, a slash, then a file name. If there is no slash, then it is both the title and filename.
						af = str.split('/')
						f = af.first.strip()
						t = af.last.strip()
						if pth.include?(f)
							arr.push({ :title => t, :file => pth })
						end
					}
				}
				# now arr contains a list of all the matching files. Save the pdfs as transcriptions and attach the txt files to a corresponding image.
				arr.uniq!()
				arr.each { |item|
					title = item[:title]
					pth = item[:file]
					if pth.include?('.pdf')
						material = Material.find_by_name(row['Title'])
						begin
							transcription = Transcription.new
							transcription.title = title
							File.open(pth) { |pdf_file| transcription.pdf = pdf_file }
							transcription.save
						rescue Exception => e
							puts "Could not save \"#{pth}\".\n#{e}\nRetrying..."
							begin
								transcription = Transcription.new
								transcription.title = title
								File.open(pth) { |pdf_file| transcription.pdf = pdf_file }
								transcription.save
							rescue Exception => e
								puts "Failed again"
							end
						end
						puts "Material not defined: /#{row['Title']}/" if material == nil
						puts "Transcription not defined: /#{row['Title']}/" if transcription == nil
						if material && transcription
							MaterialTranscription.create({ :material_id => material.id, :transcription_id => transcription.id })
							puts "#{row['Title']}    #{pth}"
						end
					elsif pth.include?('.txt')
						jpg = pth.split('/')
						jpg = jpg[jpg.length-1].split('.')
						jpg = jpg[0] + '.jpg'
						img = Image.find_by_photo_file_name(jpg)
						if img == nil
							puts "Can't find image that corresponds to the transcription: #{pth} [#{jpg}]"
						else
							File.open(pth, "r") { |f| img.transcription = f.read }
							img.save
						end
					end
				}
			end
		}
		puts "\nElapsed: #{(Time.now-start)/60.0} minutes"
	end

	desc "Clear database and solr"
	task :clear_db => [ 'environment', 'db:migrate:reset' ] do
		solr = Searcher.new()
		solr.destroy_all()
	end

	desc "Continue warming browsing cache"
	task :continue_warming_browsing_cache => [ 'environment' ] do
		Browse.warm()
	end

	desc "Warm browsing cache (invalidate the cache first)"
	task :warm_browsing_cache => [ 'environment' ] do
		Browse.invalidate()
		Browse.warm()
	end

	desc "Finalize data"
	task :finalize_data => [ 'environment' ] do
		solr = Searcher.new()
		solr.commit()
		solr.prime_spellcheck()
		puts "Recreating the memcache caches for browsing..."
		Browse.invalidate()
		Browse.warm()
	end

	desc "Clear Browse Page's cache param: page=selection=2319&subtype=hometown&type=LLS"
	task :clear_cache => [ 'environment' ] do
		which = ENV['page']
		if which == nil
			puts "Usage: rake page='xxx' import:clear_cache"
			return
		end
		arr = which.split('&')
		selection_id = nil
		type = nil
		subtype = nil
		arr.each { |el|
			arr2 = el.split('=')
			selection_id = arr2[1] if arr2[0] == 'selection'
			type = arr2[1] if arr2[0] == 'type'
			subtype = arr2[1] if arr2[0] == 'subtype'
		}
		Browse.clear(type, subtype, selection_id)
	end

	desc "Reimport all records"
	task :reimport  => [ 'environment', 'import:clear_db', 'import:law', 'import:female', 'import:non_students', 'import:objects', 'import:add_images', 'import:add_pdfs', 'import:finalize_data' ] do
	end

	def create_fixture(fname, ar)
		cols = ar.column_names
		str = "# Read about fixtures at http://ar.rubyonrails.org/classes/Fixtures.html\n\n"
		count = 0
		all = ar.all()
		all.each {|rec|
			str << "rec#{count}:\n"
			cols.each { |col|
				if rec[col].kind_of?(String)
					str << "  #{col}: \"#{rec[col].gsub('"', '\\"')}\"\n"
				else
					str << "  #{col}: #{rec[col]}\n"
				end
			}
			str << "\n"
			count += 1
		}
		File.open("#{Rails.root}/test/fixtures/#{fname}.yml", 'w') {|f| f.write(str) }
	end

	desc "Raise an error unless the RAILS_ENV is test"
	task :test_environment_only do
		raise "Must run in test mode!" unless Rails.env == 'test'
	end

	desc "Generate all the test fixtures from the database"
	task :generate_fixtures  => [ 'environment', 'test_environment_only', 'db:migrate:reset' ] do

		fname = "#{Rails.root}/lib/tasks/LLS_Student_List.csv"
		puts "~~~~~~~~~~~ Importing #{fname}..."
		children_list = []
		import_student_file(fname, 20, children_list)
		fname = "#{Rails.root}/lib/tasks/LFA_Student_List.csv"
		puts "~~~~~~~~~~~ Importing #{fname}..."
		import_student_file(fname, 20, children_list)

		# now extract all the data into the fixtures

		create_fixture("attended_years", AttendedYear)
		create_fixture("government_posts", GovernmentPost)
		create_fixture("images", Image)
		create_fixture("material_images", MaterialImage)
		create_fixture("materials", Material)
		create_fixture("offsite_materials", OffsiteMaterial)
		create_fixture("political_parties", PoliticalParty)
		create_fixture("professions", Profession)
		create_fixture("relations", Relation)
		create_fixture("residences", Residence)
		create_fixture("student_materials", StudentMaterial)
		create_fixture("student_offsite_materials", StudentOffsiteMaterial)
		create_fixture("student_political_parties", StudentPoliticalParty)
		create_fixture("student_professions", StudentProfession)
		create_fixture("student_residences", StudentResidence)
		create_fixture("students", Student)

	end

	desc "Reindex all documents -- this just reads the solr doc, then writes it back out"
	task :reindex_all => [ 'environment' ] do
		start = Time.now()
		solr = Searcher.new()
		response_hash = solr.search({ :start => 0, :page_size => 1 })
		if response_hash[:error]
			puts response_hash[:error]
		else
			response = response_hash[:response]
			page_size = 100
			total_hits = response['numFound']
			total_pages = ((total_hits + 0.0) / page_size).ceil()
			total_pages.times { |pg|
				response_hash = solr.search({ :start => pg, :page_size => page_size })
				response = response_hash[:response]
				if response_hash[:error]
					puts response_hash[:error]
				else
					response['docs'].each { |doc|
						#PUT INDEXING CHANGE CODE HERE
						doc['ac_name'] = doc['name'].split(' ')
						solr.replace_object_quick(doc)
					}
				end
				puts "-- page ##{pg+1} of #{total_pages}"
			}
			solr.commit()
		end

		puts "\nFinished in #{(Time.now-start)/60.0} minutes"
	end

end

