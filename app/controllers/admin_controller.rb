class AdminController < ApplicationController
	before_filter :authenticate_user!, :except => [:index, :new_user, :create_user]
	before_filter :is_admin, :only => [:edit_user, :update_user]

	def is_admin
        redirect_to :action => 'index' if !admin_signed_in?
	end

	def index
		@page_title = 'administrator'
		@curr_tab = 'admin'
		@revised_people = Student.all(:conditions => [ "'updated_at' > 'created_at'" ], :order => 'updated_at DESC', :limit => 10)
		@revised_objects = Material.all(:conditions => [ "'updated_at' > 'created_at'" ], :order => 'updated_at DESC', :limit => 10)
		redirect_to sign_in_path if !user_signed_in? && User.all.count > 0
	end

	def account_maintenance
		@page_title = 'administrator'
		@curr_tab = 'admin'
		if admin_signed_in?
			@users = User.all.sort { |a, b| a.email <=> b.email }
		else
			redirect_to root_path
		end
	end

	def new_row
		is_admin = admin_signed_in?
		type = params[:type]
		el = params[:el]
		id = params[:id]
		case type
		when 'category' then
			categories = Category.all().sort { |a, b| a.title <=> b.title }
			categories.collect! {|rec| [ rec.id, rec.title ] }
			categories.unshift("")
			html = self.class.helpers.one_select_row("material", type, id, categories, "", is_admin)
		when 'professions' then
			professions = Profession.all().sort { |a, b| a.title <=> b.title }
			professions.collect! {|rec| [ rec.id, rec.title ] }
			professions.unshift("")
			html = self.class.helpers.one_select_row("student", type, id, professions, "", is_admin)
		when 'political_parties' then
			political_parties = PoliticalParty.all().sort { |a, b| a.title <=> b.title }
			political_parties.collect! {|rec| [ rec.id, rec.title ] }
			political_parties.unshift("")
			html = self.class.helpers.one_select_row("student", type, id, political_parties, "", is_admin)
		when 'govt_post_Federal' then
			posts = GovernmentPost.find_all_by_which('Federal', :group => 'title').sort { |a, b| a.title <=> b.title }
			posts.collect! {|rec| [ rec.id, rec.title ] }
			posts.unshift("")
			html = self.class.helpers.one_govt_post_row("student", "Federal", posts, '', '', '', '', id, is_admin)
		when 'govt_post_State' then
			posts = GovernmentPost.find_all_by_which('State', :group => 'title').sort { |a, b| a.title <=> b.title }
			posts.collect! {|rec| [ rec.id, rec.title ] }
			posts.unshift("")
			html = self.class.helpers.one_govt_post_row("student", "State", posts, '', '', '', '', id, is_admin)
		when 'govt_post_Local' then
			posts = GovernmentPost.find_all_by_which('Local', :group => 'title').sort { |a, b| a.title <=> b.title }
			posts.collect! {|rec| [ rec.id, rec.title ] }
			posts.unshift("")
			html = self.class.helpers.one_govt_post_row("student", "Local", posts, '', '', '', '', id, is_admin)
		when 'people' then
			html = self.class.helpers.one_people_row('', 'material', id)
		when 'assoc_objects' then
			html = self.class.helpers.one_assoc_object_row('', 'material', id)
		when 'residence' then
			html = self.class.helpers.one_residence_row('student', '', '', '', id)
		when 'marriage' then
			html = self.class.helpers.one_marriage_row('student', '', '', id)
		when 'relationship' then
			html = self.class.helpers.one_relationship_row('student', '', '', id)
		when 'object' then
			html = self.class.helpers.one_object_row(-1, '', '', '', id)
		when 'offsite_material' then
			html = self.class.helpers.one_offsite_material('', '', id)
		when 'image' then
			html = self.class.helpers.one_image_upload(id)
		when 'transcription' then
			html = self.class.helpers.one_transcription_upload(id)
		else
			html = self.class.helpers.test_render(type, el, id)
		end
		
		render :text => { :el => el, :html => html }.to_json()
	end

	def validate_date
		p = params['date']
		date = VagueDate.factory(p)
		if date.kind_of?(String)
			render :text => date, :status => :bad_request
		else
			render :text => date.to_s()
		end
	end

	#
	# Hacks to go around Devise to create user
	#
	def new_user
		@resource = User.new
		@resource_name = 'user'
	end

	def create_user
		if params[:user] == nil
			redirect_to :back, :notice => 'Internal error creating user.'
		else
			confirm = params[:user]['password_confirmation']
			params[:user].delete('password_confirmation')
			if confirm == nil || confirm != params[:user]['password']
				redirect_to :back, :notice => 'Error creating user: passwords don\'t match'
			else
				user = User.new({ :permissions => params[:user]['permissions'], :email => params[:user]['email'], :password => params[:user]['password']})
				if user.save
					redirect_to :action => 'account_maintenance'
				else
					redirect_to :back, :notice => "Error creating user: #{user.errors}"
				end
			end
		end
	end

	def edit_user
		@resource = User.new
		@resource_name = 'user'
		@user = User.find(params[:id])
	end

	def update_user
		@user = User.find(params[:id])
		@user.update_attributes(params[:user])
		redirect_to :action => 'account_maintenance'
	end

	def destroy_user
		@user = User.find(params[:id])
		@user.destroy
		redirect_to :action => 'account_maintenance'
	end
end
