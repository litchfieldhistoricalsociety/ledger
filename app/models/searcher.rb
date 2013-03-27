# ------------------------------------------------------------------------
#     Copyright 2010 Litchfield Historical Society
# ----------------------------------------------------------------------------

require 'rsolr'
# documentation at: http://github.com/mwmitchell/rsolr

module RSolr::Connectable
  def send_request path, opts
    request_context = build_request path, opts
	#puts("SOLR REQUEST: #{request_context[:uri]}")
    raw_response = execute request_context
    adapt_response request_context, raw_response
  end
end

class Searcher
	def initialize
		@solr = RSolr.connect( :url=>"http://localhost:8983/solr/#{SOLR_CORE}" )
	end

	def search(options)
		suggestions = nil
		if options[:query] == nil || options[:query] == ""
			query =  "*:*"
			if options[:schools]
				query += " AND ("
				query += options[:schools].join(' OR ')
				query += ')'
			end
			response = @solr.select(:params => {
				:q=> query,
				:start=> options[:start],
				:rows=> options[:page_size]
			})
		else
			# add spell checking
			#&spellcheck=true&spellcheck.collate=true&spellcheck.q=query
			# we want to spell check only the field values, not the field names. We can receive fields in three formats:
			# value
			# name:value
			# name:[value TO value]
			# the fields are separated by AND
			use_spell_check = true
			fields = options[:query].split(" AND ")
			spellcheck = ""
			fields.each {|field|
				arr = field.split(":")
				if arr.length == 1
					spellcheck += "#{field} "
				else
					use_spell_check = false
					# Punt for now and don't do spell check on complex fields.
#					field = arr[1].gsub(/[\[\]\*\d]/, '')
#					arr2 = field.split(' TO ')
#					if arr2.length == 1
#						spellcheck += "#{field} "
#					else
#						spellcheck += "#{arr2[0]} #{arr2[1]}"
#					end
				end
			}
			#spellcheck = options[:query]

			# boost the name field
			qu = options[:query]
			qu = "(#{qu})" if qu.index(' ')
			query = "#{qu} OR name:#{qu}^10"
			if options[:schools]
				query = "(#{query}) AND ("
				query += options[:schools].join(' OR ')
				query += ')'
			end
			begin
				response = @solr.spell(:params => {
					:q=> query,
					:start=> options[:start],
					:rows=> options[:page_size],
					:spellcheck => use_spell_check,
					"spellcheck.collate" => true,
					"spellcheck.q" => spellcheck
				})
			rescue Exception => e
				str = e.to_s()
				str = str.sub('Solr Response: ', '')
				if str.index('undefined_field_') == 0
					arr = str.split('undefined_field_')
					return { :error => "There is no field called \"#{arr[1]}\"" }
				elsif str.index('Cannot parse')
					return { :error => "There was a problem with your search parameters. Try your search using \"Search the Ledger\" to learn the correct syntax." }
				elsif str.include?("Connection refused - connect(2)")
					AdminNotifier.no_solr().deliver
					return { :error => "We're sorry! Something is not working with the Search capability right now. Please try later, or try Browse instead." }
				end
				return { :error => str }
			end
			sp = response['spellcheck']
			if sp
				sug = sp['suggestions']
				if sug && sug.length > 2
					# The suggestions are an array. The last two items in the array should be "collation" and whatever the collation is.
					col_label = sug[sug.length-2]
					if col_label == 'collation'
						suggestions = sug[sug.length-1]
					end
				end
			end
		end
		return { :response => response['response'], :suggestions => suggestions }
# input parameters:
#		facet_exhibit = options[:facet][:exhibit]	# bool
#		facet_cluster = options[:facet][:cluster]	# bool
#		facet_group = options[:facet][:group]	# bool
#		facet_comment = options[:facet][:comment]	# bool
#		facet_federation = options[:facet][:federation]	#bool
#		facet_section = options[:facet][:section]	# symbol -- enum: classroom|community|peer-reviewed
#		member = options[:member]	# array of group
#		admin = options[:admin]	# array of group
#		search_terms = options[:terms]	# array of strings, they are ANDed
#		sort_by = options[:sort_by]	# symbol -- enum: relevancy|title_sort|last_modified
#		page = options[:page]	# int
#		page_size = options[:page_size]	#int
#		facet_group_id = options[:facet][:group_id]	# int
#
#		query = "federation:#{facet_federation} AND section:#{facet_section}"
#		if search_terms != nil
#			# get rid of special symbols
#			search_terms = search_terms.gsub(/\W/, ' ')
#			arr = search_terms.split(' ')
#			arr.each {|term|
#				query += " AND content:#{term}"
#			}
#		end
#
#		group_members = ""
#		member.each {|ar|
#			group_members += " OR visible_to_group_member:#{ar.id}"
#		}
#
#		group_admins = ""
#		admin.each {|ar|
#			group_admins += " OR visible_to_group_admin:#{ar.id}"
#		}
#		query += " AND (visible_to_everyone:true #{group_members} #{group_admins})"
#		if facet_group_id
#			query += " AND group_id:#{facet_group_id}"
#		end
#
#		arr = []
#		arr.push("object_type:Exhibit") if facet_exhibit
#		arr.push("object_type:Cluster") if facet_cluster
#		arr.push("object_type:Group") if facet_group
#		arr.push("object_type:DiscussionThread") if facet_comment
#		all_query = query
#		if arr.length > 0
#			query += " AND ( #{arr.join(' OR ')})"
#		end
#
#		puts "QUERY: #{query}"
#		ActiveRecord::Base.logger.info("*** USER QUERY: #{query}")
#		case sort_by
#		when :relevancy then sort = nil
#		when :title_sort then sort = [ {sort_by => :ascending }]
#		when :last_modified then sort = [ {sort_by => :descending }]
#		end
#
#		req = Solr::Request::Standard.new(:start => page*page_size, :rows => page_size, :sort => sort,
#						:query => query,
#						:field_list => [ 'key', 'object_type', 'object_id', 'last_modified' ],
#						:highlighting => {:field_list => ['text'], :fragment_size => 200, :max_analyzed_chars => 512000 })
#
#		response = @solr.send(req)
#
#		req_total = Solr::Request::Standard.new(:start => 1, :rows => 1, :query => all_query,
#						:field_list => [ 'key', 'object_type', 'object_id', 'last_modified' ])
#
#		response_total = @solr.send(req_total)
#
#		results = { :total => response_total.total_hits, :total_hits => response.total_hits, :hits => response.hits }
#		# add the highlighting to the object
#		if response.data['highlighting'] && search_terms != nil
#			highlight = response.data['highlighting']
#			results[:hits].each  {|hit|
#				this_highlight = highlight[hit['key']]
#				hit['text'] = this_highlight['text'].join("\n") if this_highlight['text']
#			}
#		end
#		# the time is a string formatted as: 1995-12-31T23:59:59Z or 1995-12-31T23:59:59.999Z
#		results[:hits].each  {|hit|
#			dt = hit['last_modified'].split('T')
#			hit['last_modified'] = nil	# in case it wasn't a valid time below.
#			if dt.length == 2
#				dat = dt[0].split('-')
#				tim = dt[1].split(':')
#				if dat.length == 3 && tim.length > 2
#					t = Time.gm(dat[0], dat[1], dat[2], tim[0], tim[1])
#					hit['last_modified'] = t
#				end
#			end
#		}
#		return results
	end

	def auto_complete(type, prefix)
		prefix = prefix.gsub("(", '').gsub(')', '')
		prefix = "\"#{prefix}\"" if prefix.index(' ')
		response = @solr.select(:params => {
			:q=> "ac_name:#{prefix} AND doc_type:#{type}",
			:start=> 0,
			:rows=> 500,
			:fl => "name"
		})
		matches = []
		docs = response['response']['docs']
		docs.each {|doc|
			matches.push(doc['name'])
		}

#		response = @solr.select(:params => { :start => 0, :rows => 0,:q => "*:*", :fq => [ "doc_type:#{type}" ],
#			"facet.field" => ['name', 'original_name', 'ac_name'],
#			"facet.prefix" => prefix,
#			"facet.missing" => false,
#			"facet.method" => 'enum',
#			"facet.mincount" => 1,
#			"facet.limit" => -1,
#			:facet => true
#			})
#		a = response['facet_counts']
#		b = a['facet_fields']
#		c = b['original_name']
#		d = b['name']
#		e = b['ac_name']
#		matches = []
#		c.each {|m|
#			matches.push(m) if m.kind_of?(String)
#		}
#		d.each {|m|
#			matches.push(m) if m.kind_of?(String)
#		}
#		e.each {|m|
#			matches.push(m) if m.kind_of?(String)
#		}
		return matches.sort()
	end

	def commit()	# called by Exhibit at the end of indexing exhibits
		@solr.commit()
	end

	def prime_spellcheck()
		@solr.spell(:params => {
			:q=> 'addams',
			:start=> 0,
			:rows=> 1,
			:spellcheck => true,
			"spellcheck.collate" => true,
			"spellcheck.build" => true
		})
	end

	def create_id(fields)
		return "#{fields[:doc_type]}_#{fields[:id]}"
	end

	def add_object(fields, relevancy = nil)
		# this takes a hash that contains a set of fields expressed as symbols, i.e. { :uri => 'something' }
		fields[:id] = create_id(fields)
		@solr.add(fields)
		commit()
	end

	def add_object_quick(fields)
		# this takes a hash that contains a set of fields expressed as symbols, i.e. { :uri => 'something' }
		fields[:id] = create_id(fields)
		@solr.add(fields)
	end

	def replace_object_quick(fields)
		# this takes a hash that contains a set of fields expressed as symbols, i.e. { :uri => 'something' }
		@solr.add(fields)
	end

	def remove_object(fields)
		id = create_id(fields)
		@solr.delete_by_query("id:#{id}")
		commit()
	end

	def destroy_all()
		@solr.delete_by_query("*:*")
		commit()
	end
end
