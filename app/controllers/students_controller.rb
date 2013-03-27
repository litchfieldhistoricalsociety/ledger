class StudentsController < ApplicationController
	before_filter :authenticate_user!, :only => [:new, :edit, :create, :update, :destroy, :export_data]

	def why
		@page_title = 'Why only immediate family?'
	end

	def format_for_export(str)
		return '' if str == nil
		str = str.gsub('"', "'")
		if str.index(',')
			str = "\"#{str}\""
		end
		return str
	end

	def export_data
		students = Student.all
		out_file = File.new("#{Rails.root}/public/students.csv", 'w')
		label1 = "id,name,unique_name,other_name,gender,room_and_board,home_town,home_state"
		label2 = "home_country,born,died,other_education,admitted_to_bar,training_with_other_lawyers"
		label3 = "federal_committees,state_committees,biographical_notes,citation_of_attendance,image_id"
		label4 = "secondary_sources,additional_notes,private_notes,benevolent_and_charitable_organizations,quotes"
		label5 = "political_parties,professions,residences,government_posts,marriages,LLS,LFA,materials,relations"
		out_file.puts "#{label1},#{label2},#{label3},#{label4},#{label5}"
		students.each {|student|
			student.fill_record()
			row = "#{student.id},#{format_for_export(student.original_name)},#{format_for_export(student.name) if student.original_name != student.name},#{format_for_export(student.other_name)},#{format_for_export(student.gender)},#{format_for_export(student.room_and_board)},#{format_for_export(student.home_town)},"
			row += "#{format_for_export(student.home_state)},#{format_for_export(student.home_country)},#{format_for_export(student.born)},#{format_for_export(student.died)},#{format_for_export(student.other_education)},#{format_for_export(student.admitted_to_bar)},"
			row += "#{format_for_export(student.training_with_other_lawyers)},#{format_for_export(student.federal_committees)},#{format_for_export(student.state_committees)},#{format_for_export(student.biographical_notes)},"
			row += "#{format_for_export(student.citation_of_attendance)},#{format_for_export(Image.find(student.image_id).photo_file_name) if student.image_id},#{format_for_export(student.secondary_sources)},#{format_for_export(student.additional_notes)},"
			row += "#{format_for_export(student.private_notes)},#{format_for_export(student.benevolent_and_charitable_organizations)},#{format_for_export(student.quotes)},"
			coll = []
			student.political_parties.each { |rec|
				coll.push(rec.title)
			}
			row += "#{format_for_export(coll.join(';'))},"
			coll = []
			student.professions.each { |rec|
				coll.push(rec.title)
			}
			row += "#{format_for_export(coll.join(';'))},"
			coll = []
			student.residences.each { |rec|
				coll.push("#{rec.town}/#{rec.state}/#{rec.country}")
			}
			row += "#{format_for_export(coll.join(';'))},"
			coll = []
			student.government_posts.each { |rec|
				coll.push("#{rec.which}/#{rec.title}/#{rec.modifier}/#{rec.location}")
			}
			row += "#{format_for_export(coll.join(';'))},"
			coll = []
			student.marriages.each { |rec|
				coll.push("#{rec.spouse_id ? Student.find(rec.spouse_id).name : "--unknown--"}/#{rec.marriage_date}")
			}
			row += "#{format_for_export(coll.join(';'))},"
			
			row += "#{format_for_export(student.years_attended_lls)},#{format_for_export(student.years_attended_lfa)},"

			coll = []
			student.materials.each { |rec|
				coll.push("#{rec.name}")
			}
			row += "#{format_for_export(coll.join(';'))},"

			out_file.puts row.gsub("\n", ' ').gsub("\r", ' ')
		}
		out_file.close()
		redirect_to "/ledger/students.csv"
	end

	# GET /students
	# GET /students.xml
	def index
		page_size = 10
		# If :q is passed in, it is a regular query string that we need to clean of weird characters.
		# If :qq is passed in, it is an advanced query string that we should pass verbatim.
		@query_string = params[:q]
		if @query_string
			session[:search_current] = @query_string
			@query_string = @query_string.gsub(/[^\w\- ]/, '') if @query_string
		else
			@query_string = params[:qq]
			session[:search_current] = @query_string
		end
		@curr_page = params[:page] || '0'
		@curr_page = @curr_page.to_i
		hsh = { :query => @query_string, :start => @curr_page*page_size, :page_size => page_size }
		if session[:search_only_students] == 'true'
			hsh[:schools] = [ 'school:LLS', 'school:LFA']
		end
		response_hash = solr().search(hsh)
		@page_title = 'Student List'
		if response_hash[:error]
			@error_msg = response_hash[:error]
			@total_hits = 0
			@total_pages = 1
			@students = []
			logger.warn "Search Query Error: #{@error_msg} ||||| /#{@query_string}/"
		else
			response = response_hash[:response]
			@suggestions = response_hash[:suggestions]
			@total_hits = response['numFound']
			@total_pages = ((@total_hits + 0.0) / page_size).ceil()
			@students = Student.convert_solr_response(response['docs'])
		end

		respond_to do |format|
			format.html # index.html.erb
			format.xml  { render :xml => @students }
		end
	end

	# GET "/students/limit?only_students=true|false"
	def limit
		session[:search_only_students] = params[:only_students]
		redirect_to({ :controller => 'students', :action => 'index', :qq => session[:search_current] })
	end

  # GET /students/1
  # GET /students/1.xml
	def show
	  @show_1 = true
	  @show_2 = true
	  @show_3 = true
	  @show_4 = true
	  @show_5 = true
		if params[:iterate] == 'next'
			params[:id] = params[:id].to_i + 1
			if Student.find_by_id(params[:id]) == nil
				params[:id] = 1
			end
		end
		if params[:iterate] == 'next_img'
			stu = Student.first(:conditions => [ 'id > ? AND image_id IS NOT NULL', params[:id] ])
			if stu == nil
				params[:id] = 1
			else
				params[:id] = stu.id
			end
		end
		if params[:iterate] == 'next_stub'
			stu = Student.first(:conditions => [ 'id > ? AND is_stub = true', params[:id] ])
			if stu == nil
				params[:id] = 1
			else
				params[:id] = stu.id
			end
		end
		@student = Student.find(params[:id])
		fill_student_rec()
		@page_title = 'Student'

		respond_to do |format|
			format.html # show.html.erb
			format.xml  { render :xml => @student }
		end
	end

  # GET /students/new
  # GET /students/new.xml
	def new
		@student = Student.new
		new_setup()
		respond_to do |format|
			format.html # new.html.erb
		end
  end
  def new_setup()
	@show_1 = true
	@show_2 = false
	@show_3 = false
	  @show_4 = false
	  @show_5 = false
	@page_title = 'New Student'
	@student.fill_record()
	@relatives = []
	@materials = []
	@marriages = []
	@professions = []
	@political_parties = []
	@federal_posts = []
	@state_posts = []
	@local_posts = []

  end

  # GET /students/1/edit
  def edit
	  # If the section is passed, then only one section is shown, otherwise all sections are shown
	  section = params[:section]

	@page_title = 'Edit Student'
	@student = Student.find(params[:id])
	edit_setup(section)
  end
  def edit_setup(section)
	  @show_1 = section != '2' && section != '3' && section != '4' && section != '5'
	  @show_2 = section != '1' && section != '3' && section != '4' && section != '5'
	  @show_3 = section != '1' && section != '2' && section != '4' && section != '5'
	  @show_4 = section != '1' && section != '2' && section != '3' && section != '5'
	  @show_5 = section != '1' && section != '2' && section != '3' && section != '4'
	fill_student_rec()
	@professions = Profession.all().sort { |a, b| a.title <=> b.title }
	@professions.collect! {|rec| [ rec.id, rec.title ] }
	@political_parties = PoliticalParty.all().sort { |a, b| a.title <=> b.title }
	@political_parties.collect! {|rec| [ rec.id, rec.title ] }
	@federal_posts = GovernmentPost.find_all_by_which('Federal', :group => 'title').sort { |a, b| a.title <=> b.title }
	@federal_posts.collect! {|rec| [ rec.id, rec.title ] }
	@state_posts = GovernmentPost.find_all_by_which('State', :group => 'title').sort { |a, b| a.title <=> b.title }
	@state_posts.collect! {|rec| [ rec.id, rec.title ] }
	@local_posts = GovernmentPost.find_all_by_which('Local', :group => 'title').sort { |a, b| a.title <=> b.title }
	@local_posts.collect! {|rec| [ rec.id, rec.title ] }
  end

	# POST /students
	# POST /students.xml
	def create
		p = params[:student]
		hash = { :original_name => p['original_name'], :sort_name => Student.make_sort_name(p['original_name']), :other_name => p['other_name'],
			:gender => p['gender'] == 'Male' ? 'M' : 'F',  :born => VagueDate.factory(p['born']).to_s, :died => VagueDate.factory(p['died']).to_s,
			:home_town => p['home_town']['town'], :home_state => p['home_town']['state'], :home_country => p['home_town']['country'],
			:biographical_notes => p['biographical_notes'], :quotes => p['quotes'], :additional_notes => p['additional_notes'], :private_notes => p['private_notes'], :is_stub => 0
		}

		@student = Student.new(hash)
		@student.generate_unique_name()

		respond_to do |format|
			if @student.save
				marriages = parse_array(p['marriage'])
				marriages.each {|marriage|
					if !marriage['name'].blank?
						Marriage.create_marriage(@student, { :name => marriage['name'] }, marriage['date'])
					end
				}
				residences = parse_array(p['residence'])
				residences.each {|residence|
					if !residence.blank?
						StudentResidence.create_residence(@student, residence)
					end
				}
				Browse.student_changed(@student, nil)
				solr().add_object(@student.to_solr())

				format.html { redirect_to(@student, :notice => 'The student was successfully created.') }
			else
				format.html {
					@page_title = 'Student'
					new_setup()
					render :action => "new"
				}
			end
		end
	end

	# PUT /students/1
	# PUT /students/1.xml
	def update
		@student_orig = Student.find(params[:id])
		@student = Student.find(params[:id])
		analyze_update_params(params, 'student')	# TODO-PER: debugging code
#		redirect_to(@student, :notice => "NOTICE: During initial testing, the modification of students has been turned off.")
#		return
		p = params[:student]
		image_id = nil
		if p[:main_image] && p[:main_image].length > 0
			arr = p[:main_image].split('/')
			if arr.length > 1
				image_id = arr[1].to_i
				if image_id == 0
					image_id = nil
				end
			end
		end
		ok = AttendedYear.validate_attended(p[:attended_lls], p[:years_lls], @student)
		ok = AttendedYear.validate_attended(p[:attended_lfa], p[:years_lfa], @student) if ok
		if ok
			hash = { :original_name => p['original_name'], :sort_name => Student.make_sort_name(p['original_name']), :other_name => p['other_name'], :gender => p['gender'] == 'Male' ? 'M' : 'F',
				:room_and_board => p['room_and_board'],  :home_town => p['home_town']['town'], :home_state => p['home_town']['state'], :home_country => p['home_town']['country'],
				:born => VagueDate.factory(p['born']).to_s, :died => VagueDate.factory(p['died']).to_s,
				:other_education => p['other_education'], :admitted_to_bar => p['admitted_to_bar'], :training_with_other_lawyers => p['training_with_other_lawyers'],
				:federal_committees => p['federal_committees'], :state_committees => p['state_committees'], :biographical_notes => p['biographical_notes'], :quotes => p['quotes'],
				:citation_of_attendance => p['citation_of_attendance'], :secondary_sources => p['secondary_sources'], :additional_notes => p['additional_notes'],
				:benevolent_and_charitable_organizations => p['benevolent_and_charitable_organizations'], :is_stub => 0, :image_id => image_id,
				:private_notes => p['private_notes']
			}
			@student.original_name = p['original_name']
			@student.generate_unique_name()
			ok = @student.update_attributes(hash)
		end

		respond_to do |format|
			if ok
				format.html {
					StudentProfession.remove_student(@student.id)
					professions = parse_array(p['professions'])
					professions.each {|profession|
						if profession['name'].to_i > 0
							StudentProfession.add_connection(@student.id, profession['name'].to_i)
						elsif profession['writein'] && profession['writein'].length > 0
							StudentProfession.add(@student.id, profession['writein'])
						end
					}
					StudentPoliticalParty.remove_student(@student.id)
					parties = parse_array(p['political_parties'])
					parties.each {|party|
						if party['name'].to_i > 0
							StudentPoliticalParty.add_connection(@student.id, party['name'].to_i)
						elsif party['writein'] && party['writein'].length > 0
							StudentPoliticalParty.add(@student.id, party['writein'])
						end
					}
					# First convert all the govt_post references to names.
					fed_posts = parse_array(p['Federal'])
					fed_posts.each {|post|
						if post['name'].to_i > 0
							post['writein'] = GovernmentPost.find(post['name'].to_i).title
						end
					}
					state_posts = parse_array(p['State'])
					state_posts.each {|post|
						if post['name'].to_i > 0
							post['writein'] = GovernmentPost.find(post['name'].to_i).title
						end
					}
					local_posts = parse_array(p['Local'])
					local_posts.each {|post|
						if post['name'].to_i > 0
							post['writein'] = GovernmentPost.find(post['name'].to_i).title
						end
					}
					# rewrite all the govt posts
					GovernmentPost.remove_student(@student.id)
					fed_posts.each {|post|
						if post['writein'] && post['writein'].length > 0
							GovernmentPost.create({ :student_id => @student.id, :which => 'Federal', :title => post['writein'], :modifier => post['modifier'],
								:location => post['location'], :time_span => post['time_span']})
						end
					}
					state_posts.each {|post|
						if post['writein'] && post['writein'].length > 0
							GovernmentPost.create({ :student_id => @student.id, :which => 'State', :title => post['writein'], :modifier => post['modifier'],
								:location => post['location'], :time_span => post['time_span']})
						end
					}
					local_posts.each {|post|
						if post['writein'] && post['writein'].length > 0
							GovernmentPost.create({ :student_id => @student.id, :which => 'Local', :title => post['writein'], :modifier => post['modifier'],
								:location => post['location'], :time_span => post['time_span']})
						end
					}

					residences = parse_array(p['residence'])
					StudentResidence.remove_student(@student.id)
					residences.each {|residence|
						if residence['town'].strip().length > 0 || residence['state'].strip().length > 0 || residence['country'].strip().length > 0
							StudentResidence.create_residence(@student, residence)
						end
					}

					OffsiteMaterial.remove_student(@student.id)
					offsite_materials = parse_array(p['offsite_material'])
					offsite_materials.each {|offsite_material|
						if offsite_material['name'] && offsite_material['url'] && offsite_material['name'].length > 0 && offsite_material['url'].length > 0
							OffsiteMaterial.create({ :student_id => @student.id, :name => offsite_material['name'], :url => offsite_material['url'] })
						end
					}

					Marriage.remove_student(@student.id)
					Relation.remove_student(@student.id)
					marriages = parse_array(p['marriage'])
					marriages.each {|marriage|
						if marriage['name'] && marriage['name'].length > 0
							Marriage.create_marriage(@student, { :name => marriage['name'] }, marriage['date'])
						end
					}

					relations = parse_array(p['relationship'])
					relation_data = { 'Brother' => 'M',
						'Sister' => 'F',
						'Daughter' => 'F',
						'Son' => 'M',
						'Husband' => 'M',
						'Wife' => 'F',
						'Father' => 'M',
						'Mother' => 'F'
					}
					relations.each {|relation|
						if relation['type'] != '' && relation['name'].strip().length > 0
							Relation.create_relationship(relation['type'], { :name => relation['name'], :gender => relation_data[relation['type']] }, @student)
						end
					}

					mats = parse_array(p['material'])
					StudentMaterial.remove_student(@student.id)
					mats.each {|material|
						if material[:name]
							m = Material.find_by_name(material[:name])
							material[:idd] = m.id if m
						end
						if material[:idd]
							StudentMaterial.create({ :student_id => @student.id, :material_id => material[:idd], :relationship => material[:relationship], :material_comment => material[:material_comment]})
						end
					}

					AttendedYear.remove_student(@student.id)
					AttendedYear.add(@student.id, 'LLS', p['years_lls']) if p['attended_lls']
					AttendedYear.add(@student.id, 'LFA', p['years_lfa']) if p['attended_lfa']

					# Now that all the other data has been set, recreate the unique name
					@student.generate_unique_name()
					@student.save!

					# Now let everyone who is interested know about the changed record.
					Browse.student_changed(@student, @student_orig)
					solr().remove_object(@student_orig.to_solr())
					solr().add_object(@student.to_solr())
					redirect_to(@student, :notice => 'The student was successfully updated.')
				}
			else
				format.html {
					@page_title = 'Student'
					edit_setup('')
					render :action => "edit"
				}
			end
		end
	end

	# DELETE /students/1
	# DELETE /students/1.xml
	def destroy
		@student = Student.find(params[:id])
#		redirect_to(@student, :notice => 'NOTICE: During initial testing, the deletion of students has been turned off.')
#		return
		Browse.student_changed(nil, @student)
		solr().remove_object(@student.to_solr())
		@student.remove_references()
		@student.destroy

		respond_to do |format|
			format.html { redirect_to({:controller => 'admin', :action => 'index'}) }
		end
	end

	private
	def fill_student_rec()
		@student.fill_record()

		@relatives = []
		rel1 = Relation.find_all_by_student1_id(@student.id)
		rel1.each {|rel|
			other_person = Student.find_by_id(rel.student2_id)
			if other_person
				@relatives.push({ :id => other_person.id, :name => other_person.name, :relationship => Relation.format_relation(rel.relationship, true, other_person.gender) })
			end
		}

		rel1 = Relation.find_all_by_student2_id(@student.id)
		rel1.each {|rel|
			other_person = Student.find_by_id(rel.student1_id)
			if other_person
				@relatives.push({ :id => other_person.id, :name => other_person.name, :relationship => Relation.format_relation(rel.relationship, false, other_person.gender) })
			end
		}

		@marriages = []
		marriages = @student.marriages
		marriages.each {|m|
			@marriages.push({ 'spouse_id' => m.spouse_id, 'marriage_date' => m.marriage_date})
		}
		mar = Marriage.find_all_by_spouse_id(@student.id)
		mar.each {|m|
			@marriages.push({ 'spouse_id' => m.student_id, 'marriage_date' => m.marriage_date})
		}

		materials = StudentMaterial.find_all_by_student_id(@student.id)
		@materials = []
		materials.each { |mat|
			material = Material.find_by_id(mat.material_id)
			@materials.push(mat) if material != nil
		}
	end

	def parse_array(hash)
		ret = []
		return ret if hash == nil
		keys = hash.keys.sort
		keys.each {|key|
			ret.push(hash[key])
		}
		return ret
	end
end
