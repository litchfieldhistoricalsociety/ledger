module ApplicationHelper
	def my_link_to(*args)
		if SUBFOLDER && SUBFOLDER.length > 0
			args[1][:script_name] = SUBFOLDER
		end
		link_to(*args)
	end

	def uploaded_image_tag(path, options = {})
		arr = path.split('?')
		path = arr[0]
		path = '/' + path
		str = image_tag(path, options)
		return str
	end

	def create_div_button(name, id, data)
		return content_tag(:div, content_tag(:span, data, {:class => 'hidden'}), { :class => "nav_button #{id}", :id => id, :title => name })
	end

	def create_plus_button(name, id, data)
		return content_tag(:div, content_tag(:span, data, {:class => 'hidden'}) + name, { :class => "#{id}", :id => id })
	end

	def create_button(name, link, id, options = {})
		html_options = options.merge({ :class => "nav_button #{id}", :id => id })
		my_link_to(name, link, html_options)
	end

	def create_js_button(name, funct, id)
		link_to_function(name, funct, { :class => "nav_button #{id}", :id => id })
	end

	def create_submit_button(name, id)
		return submit_tag(name, { :class => 'nav_button', :id => id })
	end

	def create_input_button(name, id)
		return raw("<input type='button' value='#{name}' id='#{id}' class='nav_button'>")
	end

	def create_tab_item(name, link, id, is_selected, tooltip = '')
		postfix = is_selected ? '_dn' : '_up'
		return create_button(name, link, "#{id}#{postfix}", { :title => tooltip } )
	end

	def day_format(tim)
		return "Unknown" if tim == nil
		return tim.strftime("%b %d, %Y")
	end

	def sday_format(tim)
		return "Unknown" if tim == nil
		return tim.strftime("%m-%d-%y")
	end
end
