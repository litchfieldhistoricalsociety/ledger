class SearchController < ApplicationController

	# GET "/advanced"
	def advanced
		if params['type'] == 'students' && params['students'] != nil
			params['students']['q'] = params['keywords']
			q = Student.create_query_string(params['students'])
			p = { :controller => 'students', :action => 'index', :qq => q }
			redirect_to p
		elsif params['type'] == 'materials' && params['materials'] != nil
			params['materials']['q'] = params['keywords']
			q = Material.create_query_string(params['materials'])
			p = { :controller => 'students', :action => 'index', :qq => q }
			redirect_to p
		else
			render :text => "Unknown parameters"
		end
	end

	# GET "/autocomplete"
	def autocomplete
		type = params[:type]
		prefix = params[:prefix]
		callback = params[:callback]
		empty_response = { :query => { :count => 0, :results => [] } }

		if type == nil || prefix == nil
			render :text => empty_response.to_json(), :status => :bad_request
			return
		end

		results = Searcher.new().auto_complete(type, prefix)
		if results == nil
			render :text => empty_response.to_json()
			return
		end
		ret = { :results => [ ],
			:count => results.length
		}
		results.each { |match|
			ret[:results].push({ :name => match })
		}
		resp = { :query => ret }
		render :text => "#{callback}(#{resp.to_json()});"
	end
	
	# GET "/search"
	def index
		@page_title = 'Search'
		@curr_tab = 'search'
	end

	# GET "/about"
	def about
		@page_title = 'About'
		@curr_tab = 'about'
	end

	# GET "/search/help"
	def help
		@page_title = 'Search Help'
	end
end
