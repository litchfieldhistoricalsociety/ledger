module StudentsHelper
	def list_professions(professions)
		return "" if professions == nil
		profs = []
		professions.each {|pro|
			profs.push(pro.title)
		}
		return profs.join("; ")
	end
	
	def list_residences(residences)
		return "" if residences == nil
		homes = []
		residences.each {|res|
			str = ""
			str += "#{res.town}, " if res.town != nil && res.town.length > 0
			str += "#{res.state}"
			str += " #{res.country}" if res.country != nil && res.country.length > 0 && res.country != "United States"
			homes.push(str)
		}
		return homes.join("<br />")
	end

	def list_marriages(marriages)
		return "" if marriages == nil
		marriage = []
		marriages.each {|rec|
			if rec['spouse_id']
				spouse = Student.find_by_id(rec['spouse_id'])
				if spouse
					marriage.push("#{spouse.name} (#{rec['marriage_date'] && rec['marriage_date'].length > 0 ? rec['marriage_date'] : 'unknown' })")
				end
			else
				marriage.push("Unknown (#{rec['marriage_date'] && rec['marriage_date'].length > 0 ? rec['marriage_date'] : 'unknown' })")
			end
		}
		return marriage.join("<br />")
	end

	def list_govt_posts(posts, branch)
		return "" if posts == nil
		lines = []
		posts.each {|rec|
			if rec.which == branch
				lines.push("#{rec.title} #{rec.modifier} #{"(#{rec.location})" if rec.location && rec.location.length > 0} #{rec.time_span}")
			end
		}
		return lines.join("<br />")
	end

	def list_offsite_materials(list)
		return "" if list == nil || list.length == 0
		lines = []
		list.each {|rec|
			lines.push(link_to(rec.name, rec.url))
		}
		return lines.join("<br />")
	end

	def name_row(name, is_editing, typ)
		if is_editing
			return "Editing #{typ}: #{name}"
		else
			return name
		end
	end
	
	def name_row_edit(name, is_editing, typ)
		if is_editing
			return standard_row("Name:", text_field(typ, 'original_name', { :value => name }))
		else
			return ""
		end
	end

	def hometown_row(label, rec, is_editing)
		if is_editing
			data = "Town:" + create_input_widget(rec.home_town, 'place_input', "student", :home_town, 'town') + "State:" + create_input_widget(rec.home_state, 'state_input', "student", :home_town, 'state') + "Country:" + create_input_widget(rec.home_country, 'place_input', "student", :home_town, 'country')
		else
			if (rec.home_town == nil || rec.home_town.length == 0) && (rec.home_state == nil || rec.home_state.length == 0) && (rec.home_country == nil || rec.home_country.length == 0)
				return ""
			end
			data = ""
			data += "#{rec.home_town}, " if rec.home_town != nil && rec.home_town.length > 0
			data += "#{rec.home_state}"
			data += " #{rec.home_country}" if rec.home_country != nil && rec.home_country.length > 0 && rec.home_country != "United States"
		end
		html = "<div class='student_label'>#{label}</div><div class='student_data'>#{data}</div>\n"
		return raw(html)
	end

	def removable_row(content, tooltip, id, klass = nil)
		if klass == nil
			klass = "removable_row"
		else
			klass += " removable_row"
		end
		content_tag(:div, raw(content + remove_item_div(tooltip, id)), { :id => id, :class => klass })
	end

	def insert_row(id, content = "")
		content_tag(:div, content, { :id => id })
	end

	def removable_tr(content, tooltip, id)
		content_tag(:tr, raw(content + content_tag(:td, remove_item_div(tooltip, id))), { :id => id })
	end

	def wrap_addable(label, data, type, next_id, hint)
		if next_id > 0
			data += insert_row("insert_#{type}", '')
		else
			data += insert_row("insert_#{type}", content_tag(:span, hint, { :class => 'none_defined'}))
		end
		html = standard_row(label, data) + add_item_div(label, url_for({ :controller => "admin", :action => "new_row", :type => type, :el => "insert_#{type}", :id => "#{next_id}"}))
		return raw(html)

	end

	def wrap_nonaddable(label, data, type, next_id, hint)
		if next_id > 0
			data += insert_row("insert_#{type}", '')
		else
			data += insert_row("insert_#{type}", content_tag(:span, hint, { :class => 'none_defined'}))
		end
		html = standard_row(label, data)
		return raw(html)

	end

	def residences_row(label, recs, is_editing, typ)
		return student_row(label, list_residences(recs), is_editing, typ, :none, :none) if !is_editing

		data = ""
		recs.each_with_index {|rec, i|
			data += one_residence_row(typ, rec.town, rec.state, rec.country, i)
		}
		return wrap_addable(label, data, "residence", recs.length, "None added")
	end

	def marriages_row(label, recs, is_editing, typ)
		return student_row(label, list_marriages(recs), is_editing, typ, :none, :none) if !is_editing

		data = ""
		recs.each_with_index {|rec, i|
			name = rec['spouse_id'] ? Student.find(rec['spouse_id']).name : 'Unknown'
			data += one_marriage_row(typ, name, rec['marriage_date'], i)
		}
		return wrap_addable(label, data, "marriage", recs.length, "None added")
	end
	
	def govt_post_row(label, recs, is_editing, typ, branch, sel_list)
		return student_row(label, list_govt_posts(recs, branch), is_editing, typ, :none, :none, sel_list) if !is_editing

		this_branch = []
		recs.each {|rec|
			this_branch.push(rec) if rec.which == branch
		}
		data = ""
		this_branch.each_with_index {|rec, i|
			data += one_govt_post_row(typ, branch, sel_list, rec.title, rec.modifier, rec.location, rec.time_span, i, admin_signed_in?)
		}
		return wrap_addable(label, data, "govt_post_#{branch}", this_branch.length, "None added")
	end

	def offsite_materials_row(student, is_editing)
		return student_row("", list_offsite_materials(student.offsite_materials), is_editing, "student", :is_stub, :none) if !is_editing

		data = ""
		student.offsite_materials.each_with_index {|material, i|
			data += one_offsite_material(material.name, material.url, i)
		}
		return wrap_addable("", data, "offsite_material", student.offsite_materials.length, "No objects associated")
	end

	def one_select_row(typ, field_name, i, options, sel, is_admin)
		select = removable_row(
			create_select_widget_with_writein(options, sel, typ, field_name, "#{i}", is_admin),
			"Remove #{field_name}", "multiselect_#{field_name}_#{i}")
		return content_tag(:div, select)
	end

	def one_people_row(data, typ, i)
		people = removable_row(
			create_autocomplete_widget('student', data, typ, 'assoc', "#{i}") +
			  raw("<br />") + content_tag(:span, 'Student Assoc: ') + create_input_widget('', "assoc_relationship", "material", 'assoc_relationship', "#{i}") +
			  content_tag(:span, 'Obj Assoc: ') + create_input_widget('', "assoc_material_comment", "material", 'assoc_material_comment', "#{i}"),
				'Remove person', "person_#{i}")
		return content_tag(:div, people)
	end

	def one_assoc_object_row(data, typ, i)
		people = removable_row(
			create_autocomplete_widget('material', data, typ, 'mat_assoc', "#{i}") +
			  raw("<br />") + content_tag(:span, 'This Assoc: ') + create_input_widget('', "mat_assoc_description1", "material", 'mat_assoc_description1', "#{i}") +
			  content_tag(:span, 'That Assoc: ') + create_input_widget('', "mat_assoc_description2", "material", 'mat_assoc_description2', "#{i}"),
				'Remove person', "person_#{i}")
		return content_tag(:div, people)
	end

	def one_residence_row(typ, town, state, country, i)
		return removable_row(
			"Town:" + create_input_widget(town, 'place_input', typ, 'residence', "#{i}", 'town') +
			"State:" + create_input_widget(state, 'state_input', typ, 'residence', "#{i}", 'state') +
			"Country:" + create_input_widget(country, 'place_input', typ, 'residence', "#{i}", 'country'),
		'Remove residence', "residence_#{i}")
	end

	def one_marriage_row(typ, name, date, i)
		id = make_name(typ, 'marriage', "#{i}", 'name')
		if name.length > 0
			removable_row(
				content_tag(:input, '', { :readonly => "readonly", :class => 'readonly_input', :name => id, :value => name }) +
					create_input_widget(date, 'marriage_date_input vague_date', typ, 'marriage', "#{i}", 'date') + content_tag(:span, '', { :class => 'date_error' }),
				'Remove marriage', "marriage_#{i}")
		else
			removable_row(
				create_autocomplete_widget('student', name, typ, 'marriage', "#{i}", 'name') +
					create_input_widget(date, 'marriage_date_input vague_date', typ, 'marriage', "#{i}", 'date') + content_tag(:span, '', { :class => 'date_error' }),
				'Remove marriage', "marriage_#{i}")
		end
	end

	def one_govt_post_row(typ, branch, sel_list, title, modifier, location, time_span, i, is_admin)
		removable_row(
			create_select_widget_with_writein(sel_list, title, typ, branch, "#{i}", is_admin) +
				content_tag(:span, 'Modifier: ') + create_input_widget(modifier, 'govt_input', typ, branch, "#{i}", 'modifier') + raw("<br />") +
				content_tag(:span, 'Location:') + create_input_widget(location, 'govt_input_left', typ, branch, "#{i}", 'location') +
				content_tag(:span, 'Years: ') + create_input_widget(time_span, 'govt_input', typ, branch, "#{i}", 'time_span'),
			"Remove #{branch} post", "govt_post_#{branch}_#{i}")
	end

	def one_relationship_row(type, name, relationship, i)
		id = make_name(type, "relationship", "#{i}", "type")
		id2 = make_name(type, "relationship", "#{i}", "name")
		if name.length > 0
			removable_row(
				content_tag(:input, '', { :readonly => "readonly", :class => 'readonly_input', :name => id2, :value => name }) +
					relationship_choices(id, relationship),
				'Remove relative', "relationship_#{i}")
		else
			removable_row(
				create_autocomplete_widget('student', name, type, "relationship", "#{i}", "name") +
					relationship_choices(id, relationship),
				'Remove relative', "relationship_#{i}")
		end
	end

	def one_object_row(id, name, relationship, obj_assoc, i)
		if name.length > 0
			removable_row(
				content_tag(:input, '', { :type => 'hidden', :name => "student[material][#{i}][idd]", :value => id }) +
				  content_tag(:input, '', { :readonly => "readonly", :class => 'readonly_input', :value => name }) +
				  raw("<br />") + content_tag(:span, 'Student Assoc: ') + create_input_widget(relationship, '', 'student', 'material', "#{i}", 'relationship') +
				  content_tag(:span, 'Obj Assoc: ') + create_input_widget(obj_assoc, '', 'student', 'material', "#{i}", 'material_comment'),
				'Remove object', "object_#{i}")
		else
			removable_row(
				create_autocomplete_widget('material', name, 'student', 'material', "#{i}", 'name') +
				raw("<br />") + content_tag(:span, 'Student Assoc: ') + create_input_widget(relationship, '', 'student', 'material', "#{i}", 'relationship') +
				content_tag(:span, 'Obj Assoc: ') + create_input_widget(obj_assoc, '', 'student', 'material', "#{i}", 'material_comment'),
				'Remove object', "object_#{i}")
		end
	end

	def one_offsite_material(name, url, i)
		removable_row(
			content_tag(:span, 'Name: ') + create_input_widget(name , 'student_input', 'student', 'offsite_material', "#{i}", "name") +
				content_tag(:span, 'Url: ') + create_input_widget(url , 'student_input', 'student', "offsite_material", "#{i}", "url"),
			'Remove offsite material', "offsite_materials_#{i}")
	end

	def one_image_upload(i)
		removable_row(
			create_upload_widget("material", "image", "#{i}") +
			  create_textarea_widget(" ", "material", 'image_transcription', "#{i}"),
			'Remove image', "image_#{i}")
	end

	def one_transcription_upload(i)
		removable_row(
			create_upload_widget("material", "transcription", "#{i}") +
			  create_input_widget("", "student_input", "material", 'transcription_title', "#{i}"),
			'Remove image', "image_#{i}")
	end

	def morify(data)
		data = data.gsub("\n", "<br/>")
		return data if data.length < 900
		cutoff = 800
		space = data.index(' ', cutoff)
		start_tag = data.index('<', cutoff)
		end_tag = data.index('</', cutoff)
		# The natural place for the ellipsis my be inside a tag. We'll see with this simplistic assumption that there
		# can be only one level of tags, so we'll look for an end tag before a start tag and just go beyond that.
		if end_tag != nil && end_tag == start_tag
			close_tag = data.index('>', end_tag)
			if close_tag != nil
				space = close_tag+1
			end
		end
		return data if space == nil
		first = data[0..space]
		second = data[(space+1)..data.length]
		return first + content_tag(:span, '...', { :class => 'ellipsis' }) + content_tag(:span, raw(second), { :class => 'start_hidden hidden' }) + raw("<br />") + link_to_function('[more]', '', { :class => 'more_link' }) + link_to_function('[less]', '', { :class => 'less_link hidden' })
	end

	def student_row(label, data, is_editing, typ, field_name, edit_type, options = nil)
		# in normal mode, only print the line if there is data
		# in edit mode, always print the line, but hide it if there is no data
		no_data = data == nil || (data.kind_of?(String) && data.length == 0)
		return "" if !is_editing && no_data
		if is_editing
			case edit_type
			when :string
				data = data.gsub(/ +/, ' ') if data
				data = create_textarea_widget(data, typ, field_name)
			when :input
				data = data.gsub(/ +/, ' ') if data
				data = create_input_widget(data, 'student_input', typ, field_name)
			when :gender
				data = create_select_widget("#{typ}[#{field_name}]", [ 'Female', 'Male' ], data)
			when :date
				data = create_input_widget(data, 'vague_date', typ, field_name) + content_tag(:span, '', { :class => 'date_error' })
			when :multiple_select
				data_arr = data.split(';')
				div = ""
				num_rows = data_arr.length
				if data_arr.length > 0
					data_arr.each_with_index{ |sel, i|
						div += one_select_row(typ, field_name, i, options, sel.strip(), admin_signed_in?)
					}
					div += insert_row("insert_#{field_name}")
				else
					div += insert_row("insert_#{field_name}", content_tag(:span, "None Added", { :class => 'none_defined'}))
				end
				data = raw(div)
			when :url
				label = options + ":"
				data = create_input_widget(data, 'student_input', typ, field_name)
			when :none
				data = "TODO: #{data}"
			else
				data = "ERR: Unknown edit_type #{edit_type} / #{data}"
			end
		else # is not editing
			case edit_type
			when :url
				data = link_to(options, data, { :target => '_blank' })
			when :string
				data = morify(data)
			end
		end

		html = standard_row(label, data)
		if is_editing && (edit_type == :multiple_select)
			html +=add_item_div(label, url_for({ :controller => "admin", :action => "new_row", :type => field_name, :el => "insert_#{field_name}", :id => "#{num_rows}"}))

		end
		return raw(html)
	end

	def standard_row(label, data)
		return content_tag(:div, raw(label), { :class => 'student_label' }) + content_tag(:div, raw(data), { :class => 'student_data' }) + "\n"
	end

	def remove_item_div(tooltip, id)
		return content_tag(:div, create_div_button(tooltip, 'minus_btn', id), { :class => 'minus_button' })
	end

	def add_item_div(label, callback_url)
		title = " Add #{label.chomp(':').chomp(')').chomp('s').chomp('(')}"
		return content_tag(:div, { :class => "plus_button" } ) do
			create_plus_button(title, 'plus_btn', "#{callback_url}")
		end
	end

	def make_name(typ, field_name, sub_field, sub_field2 = nil)
		name = "#{typ}[#{field_name}]"
		if sub_field
			name += "[#{sub_field}]"
		end
		if sub_field2
			name += "[#{sub_field2}]"
		end
		return name
	end

	def make_id(typ, field_name, sub_field, sub_field2 = nil)
		id = "#{typ}_#{field_name}"
		if sub_field
			id += "_#{sub_field}"
		end
		if sub_field2
			id += "_#{sub_field2}"
		end
		return id
	end

	def create_input_widget(data, klass, typ, field_name, sub_field = nil, sub_field2 = nil)
		return content_tag(:input, "", { :class => klass, :type => 'input', :value => data, :name => make_name(typ, field_name, sub_field, sub_field2), :id => make_id(typ, field_name, sub_field, sub_field2) })
	end

	def create_upload_widget(typ, field_name, sub_field)
		return content_tag(:div, content_tag(:input, "", { :class => "file_upload", :type => 'file', :name => make_name(typ, field_name, sub_field), :id => make_id(typ, field_name, sub_field) }), {})
	end

	def create_autocomplete_widget(solr_field, data, typ, field_name, sub_field = nil, sub_field2 = nil)
		return content_tag(:input, "", { :class => "auto_complete #{solr_field}", :autocomplete => 'off', :type => 'input', :value => data, :name => make_name(typ, field_name, sub_field, sub_field2), :id => make_id(typ, field_name, sub_field, sub_field2) })
	end

	def create_textarea_widget(data, typ, field_name, sub_field = nil, sub_field2 = nil)
		return content_tag(:textarea, data, { :class => 'textAreaGrow',  :type => 'input', :name => make_name(typ, field_name, sub_field, sub_field2), :id => make_id(typ, field_name, sub_field, sub_field2) })
	end
	
	def select_option(value, curr_sel)
		if value.kind_of?(Array)
			text = value[1]
			value = value[0]
		else
			text = value
		end
		if curr_sel == text || curr_sel == value
			return content_tag(:option, text, { :selected => 'selected', :value => value })
		else
			return content_tag(:option, text, { :value => value })
		end
	end

	def create_select_widget(name, choices, curr_sel, klass = nil)
		id = name.gsub(/\[/, '_').gsub(']', '')
		h = { :name => name, :id => id }
		h[:class] = klass if klass != nil
		content_tag(:select, h) do
			inner = ""
			choices.each {|choice|
				inner += select_option(choice, curr_sel)
			}
			raw(inner)
		end
	end
	
	def create_select_widget_with_writein(choices, curr_sel, typ, field_name, sub_field, is_admin)
		if is_admin
			choices.unshift([-1, '-- write in --']) if choices[0][0] != -1
			create_select_widget(make_name(typ, field_name, sub_field, 'name'), choices, curr_sel, 'write_in_select') +
				content_tag(:input, "", { :id => make_id(typ, field_name, sub_field, 'writein'), :name => make_name(typ, field_name, sub_field, 'writein'), :class => 'write_in_input hidden'})
		else
			create_select_widget(make_name(typ, field_name, sub_field, 'name'), choices, curr_sel, '')
		end
	end

	def relationship_choices(id, curr_sel)
		create_select_widget(id, [ '', 'Mother', 'Father', 'Husband', 'Wife', 'Son', 'Daughter', 'Brother', 'Sister' ], curr_sel)
	end

	def years_attended_row(student, is_editing)
		if !is_editing
			label = "Years at #{student.school}:"
			value = student.years_attended
			if student.years_attended_lls.length > 0 && student.years_attended_lfa.length > 0	# they attended both schools.
				label = "Years at school:"
				value = "LLS: #{student.years_attended_lls}; LFA: #{student.years_attended_lfa}"
			end
			return student_row(label, value, is_editing, "student", :attended_years, :attended_years)
		end

		check_hash_lls = { :type => 'checkbox', :name => 'student[attended_lls]', :value => 'LLS' }
		check_hash_lls[:checked] = 'checked' if student.years_attended_lls.length > 0
		check_hash_lfa = { :type => 'checkbox', :name => 'student[attended_lfa]', :value => 'LFA' }
		check_hash_lfa[:checked] = 'checked' if student.years_attended_lfa.length > 0

		lls_line = content_tag(:tr, {}) do
			content_tag(:td, {}) do
				content_tag(:input, "", check_hash_lls) + content_tag(:span, "Litchfield Law School")
			end +
			content_tag(:td, {}) do
				content_tag(:span, "Years:") + create_input_widget(student.years_attended_lls, "years_attended_input", "student", 'years_lls')
			end
		end
		lfa_line = content_tag(:tr, {}) do
			content_tag(:td, {}) do
				content_tag(:input, "", check_hash_lfa) + content_tag(:span, "Litchfield Female Academy")
			end +
			content_tag(:td, {}) do
				content_tag(:span, "Years:") + create_input_widget(student.years_attended_lfa, "years_attended_input", "student", 'years_lfa')
			end
		end
		table = content_tag(:table, raw(lls_line)+raw(lfa_line), { :class => 'years_attended_table' })
		return standard_row("Attended:", table)
	end

	def people_rows(students, is_editing)
		if is_editing
			content_tag(:div) do
				inner = ""
				students.each_with_index {|student, i|
					inner += removable_row(
						content_tag(:input, '', { :readonly => "readonly", :class => 'readonly_input', :name => "material[assoc][#{i}]", :value => student[:student][:name] }) +
						  raw("<br />") + content_tag(:span, "Student Assoc:") + create_input_widget(student[:relationship], "assoc_relationship", "material", 'assoc_relationship', "#{i}") +
						  content_tag(:span, "Obj Assoc:") + create_input_widget(student[:material_comment], "assoc_material_comment", "material", 'assoc_material_comment', "#{i}"),
						"Remove person", "people_#{i}", "edit_people_row")
				}
				inner = wrap_addable("Name:", inner, "people", students.length, "None Added")
				raw(inner)
			end
		else
			content_tag(:ul) do
				inner = ""
				for student in students
					inner += content_tag(:li) do
						my_link_to(student[:student][:name], { :controller => 'students', :action => 'show', :id => student[:student][:id] }) + raw("<br />") + content_tag(:span,  student[:relationship], { :class => 'relationship'})
					end
				end
				raw(inner)
			end
		end
	end

	def assoc_objects_rows(materials, is_editing)
		if is_editing
			content_tag(:div) do
				inner = ""
				materials.each_with_index {|material, i|
					inner += removable_row(
						content_tag(:input, '', { :readonly => "readonly", :class => 'readonly_input', :name => "material[mat_assoc][#{i}]", :value => material[:material][:name] }) +
						  raw("<br />") + content_tag(:span, "This Assoc:") + create_input_widget(material[:this_description], "mat_assoc_description1", "material", 'mat_assoc_description1', "#{i}") +
						  content_tag(:span, "That Assoc:") + create_input_widget(material[:that_description], "mat_assoc_description2", "material", 'mat_assoc_description2', "#{i}"),
						"Remove person", "people_#{i}", "edit_people_row")
				}
				inner = wrap_addable("Object:", inner, "assoc_objects", materials.length, "None Added")
				raw(inner)
			end
		else
			content_tag(:ul) do
				inner = ""
				for material in materials
					inner += content_tag(:li) do
						my_link_to(material[:material][:name], { :controller => 'materials', :action => 'show', :id => material[:material][:id] }) + raw("<br />") + content_tag(:span,  material[:that_description], { :class => 'relationship'})
					end
				end
				raw(inner)
			end
		end
	end

	def create_button2(name, link, id, options = {})
		html_options = options.merge({ :class => id, :id => id })
		my_link_to(name, link, html_options)
	end

	def images_rows(images, is_editing, is_logged_in)
		if !is_editing && (images == nil || images.length == 0)
			return content_tag(:div, image_tag('image_not_yet_available.png'))
		end
		html = ""
		carousel = ""
		if !is_editing
			pix = ''
			has_trans = false
			images.each { |img|
				has_trans = true if img.transcription && img.transcription.length > 0
			}
			images.each_with_index { |img, i|
				imgDiv = content_tag('div', uploaded_image_tag(img.photo.url(:small)), { :class => "lightbox_thumbnail", :title => "click for larger image" })
				if is_logged_in
					imgDiv += create_button2("Delete", { :controller => 'materials', :action => 'remove_image', :id => img.id }, 'remove_file_btn_carousel fxn_confirm', { 'data-confirm' => 'Are you sure you want to delete this image?' })
				end
				if img.transcription && img.transcription.length > 0
					cls = "img_transcription_carousel"
					imgDiv += content_tag('div', img.transcription, { :class => cls })
				end
				pix += content_tag('li', content_tag('div', raw(imgDiv)), { :class => has_trans ? 'tall' : 'short'})
			}
			carousel += content_tag('table', content_tag('tr', content_tag('td', content_tag('div', '', { :id => 'carousel_left' })) +
				content_tag('td', content_tag('div', content_tag('ol', raw(pix)), { :id => 'carousel' })) +
				content_tag('td', content_tag('div', '', { :id => 'carousel_right' }))))
		end
		images.each_with_index { |img, i|
			html += content_tag(:div) do
				inner = ""
				if is_editing
					#inner += content_tag('hr')
					inner += 
						content_tag(:div, raw(
							content_tag('span', {}) do
								content_tag('div', uploaded_image_tag(img.photo.url(:thumb)), { :class => "lightbox_thumbnail", :title => "click for larger image" }) #+
								#content_tag(:div, create_js_button("browse", "", 'browse_for_image_btn'), { :class => 'browse_button', :title => "Browse for image" })
							end +
							content_tag('div', { :class => 'image_transcription'}) do
								content_tag(:div, "Image transcription:", {}) +
								content_tag('div', create_textarea_widget(img.transcription, 'material', 'images', "transcription", "#{img.id}"), {})
							end))
#				else
#					if is_logged_in
#						inner += create_button("Delete", { :controller => 'materials', :action => 'remove_image', :id => img.id }, 'remove_file_btn fxn_confirm', { 'data-confirm' => 'Are you sure you want to delete this image?' })
#					end
#					if img.transcription && img.transcription.length > 0
#						cls = "img_transcription"
#						cls += " img_transcription_edit" if is_logged_in
#						inner += content_tag('div', img.transcription, { :class => cls })
#					end
#					inner += content_tag('div', uploaded_image_tag(img.photo.url(:small)), { :class => "lightbox_thumbnail material_picture", :title => "click for larger image" })
				end
				raw(inner)
			end
		}
		return wrap_nonaddable("Image:", html, "image", images.length, "No images uploaded") if is_editing
		html = standard_row('', html)
		return raw(carousel) + html
	end

	def create_transcription_link(name, transcription)
		return link_to(name, transcription.pdf.url, { :target => "_blank", :title => 'click to preview PDF' }) +
			content_tag('span', " (PDF, #{transcription['pdf_file_size'].to_i/1024}K)", {})
	end

	def transcriptions_rows(transcriptions, is_editing, is_logged_in)
		html = ""
		transcriptions.each_with_index { |transcription, i|
			html += content_tag(:div) do
				inner = ""
				if is_editing
					inner += 
						content_tag(:div, raw(
							content_tag('span', {}) do
								create_transcription_link(transcription['pdf_file_name'], transcription)
							end +
							content_tag('div', {}) do
								content_tag('span', "Title:", {}) + create_input_widget(transcription['title'], 'transcription_input', 'material', 'transcriptions', "title", "#{i}")
							end))
				else
					if is_logged_in
						inner += create_button("Delete", { :controller => 'materials', :action => 'remove_transcription', :id => transcription.id }, 'remove_file_btn fxn_confirm', { 'data-confirm' => 'Are you sure you want to delete this transcription?' })
					end
					inner += create_transcription_link(transcription.title, transcription)
					inner += content_tag('br')
				end
				raw(inner)
			end
		}
		return wrap_nonaddable("Transcription:", html, "transcription", transcriptions.length, "No PDF transcriptions uploaded") if is_editing
		html = standard_row('', html)
		return raw(html)
	end

	def object_rows(materials, is_editing)
		if is_editing
			html = content_tag(:div) do
				inner = ""
				materials.each_with_index {|mat, i|
					material = Material.find_by_id(mat.material_id)
					inner += one_object_row(material[:id], material[:name], mat.relationship, mat.material_comment, i)
				}
				raw(inner)
			end
		else
			html = content_tag(:ul) do
				inner = ""
				for mat in materials
					material = Material.find_by_id(mat.material_id)
					inner += content_tag(:li) do
						raw("#{my_link_to material[:name], { :controller => 'materials', :action => 'show', :id => material[:id] }}<br />#{content_tag(:span, mat[:material_comment], { :class => "bullet_second_row"}) if mat[:material_comment] && mat[:material_comment].length > 0}")
					end
				end
				raw(inner)
			end
		end
		return wrap_addable("Object:", html, "object", materials.length, "No objects associated") if is_editing
		html = standard_row('', html) if is_editing
		return raw(html)
	end

	def relative_rows(relatives, is_editing)
		if is_editing
			html = content_tag(:div) do
				inner = ""
				relatives.each_with_index {|relative, i|
					inner += one_relationship_row('student', relative[:name], relative[:relationship], i)
				}
				raw(inner)
			end
		else
			html = content_tag(:ul) do
				inner = ""
				for relative in relatives
					inner += content_tag(:li) do
						yrs = AttendedYear.find_all_by_student_id(relative[:id])
						attendence = yrs == nil ? "" : raw("<br />") + content_tag(:span,  AttendedYear.to_school_year_string(yrs), { :class => 'relationship'})
						raw("#{my_link_to relative[:name], { :controller => 'students', :action => 'show', :id => relative[:id] }}<br />#{content_tag(:span,  relative[:relationship], { :class => 'relationship'})}#{attendence}")
					end
				end
				raw(inner)
			end
		end
		return wrap_addable("Relationship:", html, "relationship", relatives.length, "None Added") if is_editing
		html = standard_row('', html) if is_editing
		return raw(html)
	end
	
	def main_student_image(student, gender, is_editing)
		return "" if is_editing
		no_portrait = true
		if student.image_id != nil
			img = Image.find_by_id(student.image_id)
			if img
				main_image = img.photo.url(:small)
				# TODO-PER: can there really be more than one material record for an object: it seems like there should only be one.
				if img.materials.length > 0
					material = img.materials[0]
					caption = raw("#{material.name}<br />#{material.author}")
					no_portrait = false
				else
					caption = "No image available"
				end
				lightbox = true
			else
				main_image = (gender == 'Male' ? 'images/generic_male.gif' : 'images/generic_female.gif')
				caption = "No image available"
				lightbox = false
			end
		else
			main_image = (gender == 'Male' ? 'images/generic_male.gif' : 'images/generic_female.gif')
			caption = "No image available"
			lightbox = false
		end
		content_tag(:div, { :class => "#{'lightbox_thumbnail ' if lightbox }student_portrait", :title => "#{'click for larger image' if lightbox }" }) do
			uploaded_image_tag(main_image) + content_tag(:div, caption, { :class => "#{'no_portrait ' if no_portrait }student_portrait_caption" })
		end
	end

	def main_student_image_edit(student, gender, is_editing, materials)
		return "" if !is_editing
		generic_img = (gender == 'Male' ? 'images/generic_male.gif' : 'images/generic_female.gif')
		if student.image_id != nil
			img = Image.find_by_id(student.image_id)
			if img
				main_image = img.photo.url(:small)
				lightbox = true
			else
				main_image = generic_img
				lightbox = false
			end
		else
			main_image = generic_img
			lightbox = false
		end
		link = ""

		lightbox = false
		choices = [ [ generic_img, '' ] ]
		curr_sel = main_image
		materials.each {|smat|
			mat = Material.find_by_id(smat.material_id)
			avail_imgs = mat.images
			avail_imgs.each_with_index {|t, i|
				nm = mat.name
				nm += " (#{i})" if avail_imgs.length > 1
				#puts "IMAGECHOICE: #{t.photo.url(:small)} :::: #{nm}"
				choices.push([ t.photo.url(:small), nm])
			}
		}
		if choices.length > 1
			link = create_select_widget('student[main_image]', choices, curr_sel)
		else
			reason = materials.length == 0 ? "No associated objects" : "No images in associated objects"
			link =  content_tag(:span, "Can't select portrait: #{reason}", { :class => 'none_defined'})
		end

		html = content_tag(:div, { :class => "#{'lightbox_thumbnail ' if lightbox }", :title => "#{'click for larger image' if lightbox }" }) do
			if choices.length > 1
				link + content_tag('br') + uploaded_image_tag(main_image, { :class => 'main_image_img' })
			else
				link
			end
		end
		return standard_row("Portrait:", html)
	end

	def edit_collection(is_editing)
		if is_editing
			return raw("<div class='edit_collection'>")
		else
			return ""
		end
	end

	def edit_collection_end(is_editing)
		if is_editing
			return raw("</div>")
		else
			return ""
		end
	end

	def custom_error_messages_helper(mod)
		return "" if mod.errors.length == 0
		html = ""
		html << '<div class="errors">Record not saved because of the following errors:<br /><br />'
		mod.errors.each do |attr, error|
			#if !(attr =~ /\./)
				html << '<div class="error">'
				html << "#{attr.to_s.gsub('_', ' ').capitalize()}: #{error}"
				html << '</div>'
			#end
		end
		html << '</div>'
		return raw(html)
	end

end
