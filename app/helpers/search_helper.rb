module SearchHelper
	def pagination_links(first, last, url, curr_page)
		html = ""
		first.upto(last) {|pg|
			if pg == curr_page
				html << "#{pg+1}" << " "
			else
				html << my_link_to(pg+1, url.merge({:page => pg})) << " "
			end
		}
		return raw(html)
	end
end
