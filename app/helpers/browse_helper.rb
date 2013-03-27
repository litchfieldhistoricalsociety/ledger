module BrowseHelper
	def create_three_column_link_item(arr, col, row, action, param_name)
		return "" if arr[col].length <= row
		item = arr[col][row]
		if item[:options]
			html = "<span class='toggleTree' id='toggle_#{item[:id]}'>#{item[:label]} (#{item[:options].length})</span>\n"
			item[:options].each {|rec|
				rec[:label] =  "&bull; #{rec[:label]}"
				html += "<div class='indent hidden child_#{item[:id]}'>#{create_link(rec, action, param_name)}</div>\n"
			}
			return raw(html)
	#			return raw("<span class='browse_label'>#{item[:label]}</span>")
		elsif item[:id]
			return create_link(item, action, param_name)
		elsif item[:label].length > 0
			return raw("<span class='browse_label'>#{item[:label]}</span>")
		else
			return raw("&nbsp;")
		end
	end

# This is the version that creates the triangle with the dropdown
#	def create_three_column_link_item(arr, col, row, action, param_name)
#		return "" if arr[col].length <= row
#		item = arr[col][row]
#		if item[:options]
#			html = "<span class='open_tree hidden' id='opened_#{item[:id]}'>#{image_tag('arrow_opened.gif')}</span>"
#			html += "<span class='close_tree' id='closed_#{item[:id]}'>#{image_tag('arrow_closed.gif')}</span>"
#			html += "<span>#{item[:label]}</span>\n"
#			item[:options].each {|rec|
#				html += "<div class='indent hidden child_#{item[:id]}'>#{create_link(rec, action, param_name)}</div>\n"
#			}
#			return raw(html)
#	#			return raw("<span class='browse_label'>#{item[:label]}</span>")
#		elsif item[:id]
#			return create_link(item, action, param_name)
#		elsif item[:label].length > 0
#			return raw("<span class='browse_label'>#{item[:label]}</span>")
#		else
#			return raw("&nbsp;")
#		end
#	end
#
	def create_link(item, action, param_name)
		destination = action
		destination[param_name] = item[:id]
		label = item[:label]
		label = "Miscellaneous" if label == nil || label.length == 0
		return link_to(raw(label), destination)
#		return raw(label) + "[#{destination.to_s}]"
	end

	def create_date_range(str, action, curr_sel, prepend = nil)
		link = action
		if prepend == nil
			link[:selection] = str
		else
			link[:selection] = "#{prepend}:#{str}"
		end
		is_current = str == curr_sel
		return str if is_current
		return link_to(str, link)
	end

	def breadcrumb(crumbs)
		# crumbs is an array of hashes. The hashes contain :label and :type
		links = []
		crumbs.each {|crumb|
			links.push(link_to(crumb[:label], :action => 'index', :type => crumb[:type], :subtype => crumb[:subtype]))
		}
		return raw("#{links.join(' &gt; ')}")
	end

	def create_browse_submenu(sub_menu, base_url, selection)
		items = []
		sub_menu.each {|key,value|
			items.push(create_date_range(key, base_url, selection))
		}
		html = items.join(" &bull; ")
		return raw(html)
	end

	def create_browse_submenu2(sub_menu, base_url, selection, prepend)
		items = []
		sub_menu.each {|key|
			items.push(create_date_range(key, base_url, selection, prepend))
		}
		html = items.join(" &bull; ")
		return raw(html)
	end
end
