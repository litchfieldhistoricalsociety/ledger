class MaterialsController < ApplicationController
	before_filter :authenticate_user!, :only => [:new, :edit, :create, :update, :destroy, :export_data]

	def format_for_export(str)
		return '' if str == nil
		str = str.gsub('"', "'")
		if str.index(',')
			str = "\"#{str}\""
		end
		return str
	end

	def export_data
		materials = Material.all
		out_file = File.new("#{Rails.root}/public/materials.csv", 'w')
		out_file.puts "id,name,unique_name,object_id,accession_num,url,author,date,collection,held_at,associated_place,medium,size,description,private_notes,categories,images,associated_objects,transcriptions,students"
		materials.each {|material|
			row = "#{material.id},#{format_for_export(material.original_name)},#{format_for_export(material.name) if material.original_name != material.name},#{format_for_export(material.object_id)},#{format_for_export(material.accession_num)},#{format_for_export(material.url)},#{format_for_export(material.author)},"
			row += "#{format_for_export(material.material_date)},#{format_for_export(material.collection)},#{format_for_export(material.held_at)},#{format_for_export(material.associated_place)},#{format_for_export(material.medium)},#{format_for_export(material.size)},"
			row += "#{format_for_export(material.description)},#{format_for_export(material.private_notes)},"
			coll = []
			material.categories.each { |category|
				coll.push(category.title)
			}
			row += "#{format_for_export(coll.join(';'))},"
			coll = []
			material.images.each { |image|
				coll.push("#{image.photo_file_name} - #{image.transcription}")
			}
			row += "#{format_for_export(coll.join(';'))},"
			coll = []
			mats = MaterialMaterial.find_all_by_material1_id(material.id)
			mats.each { |mat|
				coll.push("#{Material.find(mat.material2_id).name} - #{mat.description1}/#{mat.description2};")
			}
			mats = MaterialMaterial.find_all_by_material2_id(material.id)
			mats.each { |mat|
				coll.push("#{Material.find(mat.material1_id).name} - #{mat.description1}/#{mat.description2};")
			}
			row += "#{format_for_export(coll.join(';'))},"
			coll = []
			material.transcriptions.each { |transcription|
				coll.push("#{transcription.title} - #{transcription.pdf_file_name}")
			}
			row += "#{format_for_export(coll.join(';'))},"
			coll = []
			material.students.each { |student|
				coll.push("#{student.name}")
			}
			row += "#{format_for_export(coll.join(';'))}"
			out_file.puts row.gsub("\n", ' ').gsub("\r", ' ')
		}
		out_file.close()
		redirect_to "/ledger/materials.csv"
	end

	# GET /materials
	# GET /materials.xml
	def index
		@page_title = 'Object List'
		@materials = Material.all

		respond_to do |format|
			format.html # index.html.erb
			format.xml  { render :xml => @materials }
		end
	end

	# GET /materials/1
	# GET /materials/1.xml
	def show
		if params[:iterate] == 'next'
			params[:id] = params[:id].to_i + 1
			if Material.find_by_id(params[:id]) == nil
				params[:id] = 1
			end
		end
		if params[:iterate] == 'prev'
			params[:id] = params[:id].to_i - 1
			if Material.find_by_id(params[:id]) == nil
				params[:id] = 1
			end
		end
		@page_title = 'Object'
		@material = Material.find(params[:id])
		find_students()
		find_materials()

		respond_to do |format|
			format.html # show.html.erb
			format.xml  { render :xml => @material }
		end
	end

	# GET /materials/new
	# GET /materials/new.xml
	def new
		@material = Material.new
		new_setup()

		respond_to do |format|
			format.html # new.html.erb
			format.xml  { render :xml => @material }
		end
	end

	def new_setup
		@page_title = 'New Object'
		@students = []
		@materials = []
		@categories = Category.all().sort { |a, b| a.title <=> b.title }
		@categories.collect! {|rec| [ rec.id, rec.title ] }
		@categories.unshift([-2, ''])
	end

	# GET /materials/1/edit
	def edit
		@material = Material.find(params[:id])
		edit_setup()
	end

	def edit_setup
		@page_title = 'Edit Object'
		find_students()
		find_materials()
		@categories = Category.all().sort { |a, b| a.title <=> b.title }
		@categories.collect! {|rec| [ rec.id, rec.title ] }
		@categories.unshift([-2, ''])
	end

	def add_image
		if params[:file]
			img = Image.new
			img.photo = params[:file]
			img.save
			MaterialImage.create({ :material_id => params[:id], :image_id => img.id })
		end

		redirect_to :back
	end

	def add_transcription
		if params[:file]
			img = Transcription.new
			img.pdf = params[:file]
			# TODO-PER: Hack in a title for now from the file name
			title = img.pdf_file_name
			img.title = title.gsub(".pdf", "").gsub(".PDF", "").gsub("_", " ")
			img.save
			MaterialTranscription.create({ :material_id => params[:id], :transcription_id => img.id })
		end

		redirect_to :back
	end

	def remove_transcription
		id = params[:id]
		rec = MaterialTranscription.find_by_transcription_id(id)
		rec.destroy() if rec != nil
		rec = Transcription.find_by_id(id)
		rec.destroy() if rec != nil
		redirect_to :back
	end

	def remove_image
		id = params[:id]
		rec = MaterialImage.find_by_image_id(id)
		rec.destroy() if rec != nil
		rec = Image.find_by_id(id)
		rec.destroy() if rec != nil
		redirect_to :back
	end

	# POST /materials
	# POST /materials.xml
	def create
		p = params[:material]
		hash = { :original_name => p['original_name'], :object_id => p['object_id'], :accession_num => p['accession_num'],
			:url => p['url'],  :author => p['author'], :material_date => VagueDate.factory(p['material_date']).to_s,
			:collection => p['collection'], :held_at => p['held_at'], :associated_place => p['associated_place'], :medium => p['medium'],
			:size => p['size'], :description => p['description'], :private_notes => p['private_notes']
		}
		@material = Material.new(hash)
		@material.generate_unique_name()

		respond_to do |format|
			if @material.save
				categories = parse_array(p['category'])
				categories.each {|category|
					if category['name'].to_i > 0
						MaterialCategory.add_connection(@material.id, category['name'].to_i)
					elsif !category['writein'].blank?
						MaterialCategory.add(@material.id, category['writein'])
					end
				}
				students = parse_array(p['assoc'])
				students.each {|student|
					rec = Student.get_or_create({ :name => student })
					if rec
						StudentMaterial.create({ :student_id => rec.id, :material_id => @material.id })
					end
				}

				Browse.material_changed(@material, nil)
				solr().add_object(@material.to_solr())
				format.html { redirect_to(@material, :notice => 'The object was successfully created.') }
			else
				format.html {
					new_setup()
					render :action => "new"
				}
			end
		end
	end

	# PUT /materials/1
	# PUT /materials/1.xml
	def update
		material_orig = Material.find(params[:id]).to_solr
#		@errors = Material.validate_all(params['material'])
		@material = Material.find(params[:id])
#		if @errors.length == 0
			analyze_update_params(params, 'material')	# TODO-PER: debugging code
#			redirect_to(@material, :notice => 'NOTICE: During initial testing, the modification of objects has been turned off.')
#			return
			p = params[:material]
			hash = { :original_name => p['original_name'], :object_id => p['object_id'], :accession_num => p['accession_num'],
				:url => p['url'],  :author => p['author'], :material_date => VagueDate.factory(p['material_date']).to_s,
				:collection => p['collection'], :held_at => p['held_at'], :associated_place => p['associated_place'], :medium => p['medium'],
				:size => p['size'], :description => p['description'], :private_notes => p['private_notes']
			}
			@material.original_name = p['original_name']
			@material.generate_unique_name()
			ok = @material.update_attributes(hash)
#		else
#			ok = false
#		end

		respond_to do |format|
			if ok
				format.html {
					MaterialCategory.remove_material(@material.id)
					categories = parse_array(p['category'])
					categories.each {|category|
						if category['name'].to_i > 0
							MaterialCategory.add_connection(@material.id, category['name'].to_i)
						else
							MaterialCategory.add(@material.id, category['writein'])
						end
					}
					StudentMaterial.remove_material(@material.id)
					students = parse_array(p['assoc'])
					relationships = parse_array(p['assoc_relationship'])
					material_comment = parse_array(p['assoc_material_comment'])
					students.each_with_index {|student, i|
						rec = Student.get_or_create({ :name => student })
						if rec
							StudentMaterial.create({ :student_id => rec.id, :material_id => @material.id, :relationship => relationships[i], :material_comment => material_comment[i] })
						end
					}
					MaterialMaterial.remove_material(@material.id)
					materials = parse_array(p['mat_assoc'])
					description1 = parse_array(p['mat_assoc_description1'])
					description2 = parse_array(p['mat_assoc_description2'])
					materials.each_with_index {|material, i|
						rec = Material.find_by_name(material)
						if rec
							MaterialMaterial.factory(@material.id, rec.id, description1[i], description2[i])
						end
					}
					if p['transcriptions']
						titles = parse_array(p['transcriptions']['title'])
						transcription_recs = MaterialTranscription.find_all_by_material_id(@material.id)
						transcription_recs.each_with_index { |rec, i|
							title = titles.length > i ? titles[i] : ''
							trans = Transcription.find(rec.transcription_id)
							trans.title = title
							trans.save()
						}
					end

					if p['images']
						images = parse_hash(p['images']['transcription'])
						image_recs = @material.images # MaterialImage.find_all_by_material_id(@material.id)
						@material.images.sort { |a,b| a.id <=> b.id }.each_with_index { |rec, i|
							#tran = images.length > i ? images[i] : ''
							#im = Image.find(rec.image_id)
							#im.transcription = tran
							#im.save()
							if images[rec.id.to_s] && rec.transcription != images[rec.id.to_s]
								rec.transcription = images[rec.id.to_s]
								rec.save
							end
						}
					end

					# Now that all the other data has been set, recreate the unique name
					@material.generate_unique_name()
					@material.save!

					# Now let everyone who is interested know about the changed record.
					Browse.material_changed(@material.to_solr(), material_orig)
					solr().remove_object(material_orig)
					solr().add_object(@material.to_solr())
					redirect_to(@material, :notice => 'The object was successfully updated.')
				}
			else
				format.html {
					edit_setup()
					render :action => "edit"
				}
			end
		end
	end

	# DELETE /materials/1
	# DELETE /materials/1.xml
	def destroy
		@material = Material.find(params[:id])
#		redirect_to(@material, :notice => 'NOTICE: During initial testing, the deletion of objects has been turned off.')
#		return
		Browse.material_changed(nil, @material.to_solr())
		solr().remove_object(@material.to_solr())
		@material.remove_references()
		@material.destroy

		respond_to do |format|
			format.html { redirect_to({:controller => 'admin', :action => 'index'}) }
		end
	end

	private
	def find_students
		students = StudentMaterial.find_all_by_material_id(@material.id)
		@students = []
		students.each { |stu|
			student = Student.find_by_id(stu.student_id)
			@students.push({ :student => student, :relationship => stu.relationship }) if student != nil
		}
	end

	def find_materials
		@materials = []
		materials = MaterialMaterial.find_all_by_material1_id(@material.id)
		materials.each { |mat|
			material = Material.find_by_id(mat.material2_id)
			@materials.push({ :material => material, :this_description => mat.description1, :that_description => mat.description2 }) if material != nil
		}
		materials = MaterialMaterial.find_all_by_material2_id(@material.id)
		materials.each { |mat|
			material = Material.find_by_id(mat.material1_id)
			@materials.push({ :material => material, :this_description => mat.description2, :that_description => mat.description1 }) if material != nil
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

	def parse_hash(hash)
		ret = {}
		return ret if hash == nil
		keys = hash.keys
		keys.each {|key|
			ret[key] = hash[key]
		}
		return ret
	end
end
