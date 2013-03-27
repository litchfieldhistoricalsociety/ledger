class BrowseController < ApplicationController
	def index
		@page_title = 'Browse'
		@page_title = 'browse'
		@curr_tab = 'browse'
		@type = params['type']
		@subtype = params['subtype']
		selection_id = params['selection']

		ret = Browse.get(@type, @subtype, selection_id)
		@selection = ret[:selection]
		@list = ret[:list]
		@sub_menu = ret[:sub_menu]
		@sub_selection = ret[:sub_selection]
		@total = ret[:total]
		@country_total = ret[:country_total]

		if @type == nil
			@total_lls = AttendedYear.count({ :distinct => true, :select => 'student_id', :conditions => [ 'school = ?', 'LLS'] })
			@total_lfa = AttendedYear.count({ :distinct => true, :select => 'student_id', :conditions => [ 'school = ?', 'LFA'] })
			@total_obj = Material.count
			sql = "select students.id from students left outer join attended_years on students.id = attended_years.student_id where school is null"
			match = ActiveRecord::Base.connection.execute(sql)
			@total_non = match.count
			sql = "select distinct marriages.id from marriages inner join attended_years as ay1 on marriages.student_id = ay1.student_id inner join attended_years as ay2 on marriages.spouse_id = ay2.student_id"
			match = ActiveRecord::Base.connection.execute(sql)
			@total_marriages = match.count
		end
	end
end
