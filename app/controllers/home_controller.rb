class HomeController < ApplicationController
	# GET "/"
	def index
		@page_title = 'Home'
		@features = []
		rec = Student.find_by_name("Tapping Reeve")
		@features.push({ :rec => rec, :text => 'Tapping Reeve, an American jurist and founder of the Litchfield Law School, helped bring order to the law through systematic and integrated instruction.' }) if rec != nil
		rec = Student.find_by_name("Sarah Pierce")
		@features.push({ :rec => rec, :text => 'In 1792 Sarah Pierce started teaching girls in her home and by 1798 the school became so successful that an Academy building was built.' }) if rec != nil
		@total_lls = AttendedYear.count({ :distinct => true, :select => 'student_id', :conditions => [ 'school = ?', 'LLS'] })
		@total_lfa = AttendedYear.count({ :distinct => true, :select => 'student_id', :conditions => [ 'school = ?', 'LFA'] })
		sql = "select distinct students.id from `students` inner join attended_years on students.id = `attended_years`.`student_id` where gender = 'M' and school='LFA'"
		match = ActiveRecord::Base.connection.execute(sql)
		@total_lfa_men = match.count
		sql = "select distinct students.id from `students` inner join attended_years on students.id = `attended_years`.`student_id` where gender = 'F' and school='LFA'"
		match = ActiveRecord::Base.connection.execute(sql)
		@total_lfa_women = match.count
	end

	def contact_us
		@page_title = 'Contact Us'
		@referrer = env['HTTP_REFERER']
	end

	def mail
		p = params[:mail]
		name = p[:name]
		email = p[:email]
		description = p[:description]
		referrer = p[:referrer]
#		if referrer.index('/materials/') || referrer.index('/students/')
		AdminNotifier.contact(name, email, description, referrer).deliver
#		end

		redirect_to referrer
	end
end
