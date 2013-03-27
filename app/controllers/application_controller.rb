class ApplicationController < ActionController::Base
	protect_from_forgery
	layout 'litchfield'

	def solr()
		@solr = @solr || Searcher.new()
		return @solr
	end

	def test_exception_notifier
		raise 'This is a test. This is only a test.'
	end

	helper_method :admin_signed_in?
	def admin_signed_in?
		if user_signed_in? && current_user.permissions == 'Administrator'
			return true
		end
		return false
	end

	helper_method :full_signed_in?
	def full_signed_in?
		if user_signed_in? && (current_user.permissions == 'Administrator' || current_user.permissions == 'Full')
			return true
		end
		return false
	end

	def analyze_update_params(params, type)
		normal = params[type]
		report = params.clone
		report.delete_if { |p,q|
			p == 'commit' || p == "authenticity_token" || p == "_method" || p == "_snowman" || p == "action" || p == "id" || p == 'controller' || p == type
		}
		strays = report.length > 0 ? "These are not under #{type}: \n#{report.inspect.gsub(",", ",\n")}\n" : ""
		report = ""
		normal.each {|p,q|
			report << "--- #{p} ---\n#{q.inspect.gsub(",",",\n")}\n"
		}
		puts strays+report
		return strays+report
	end
end
