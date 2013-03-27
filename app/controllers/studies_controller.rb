class StudiesController < ApplicationController
	def index
		@page_title = 'Studies'
		@curr_tab = 'studies'
	end

	def history
		@page_title = 'Litchfield History'
		@curr_tab = 'studies'
	end

	def lls_bibliography
		@page_title = 'LLS Bibliography'
		@curr_tab = 'studies'
	end

	def lfa_bibliography
		@page_title = 'LFA Bibliography'
		@curr_tab = 'studies'
	end

	def history_school
		@page_title = 'Law School History'
		@curr_tab = 'studies'
	end

	def history_lfa
		@page_title = 'Female Academy History'
		@curr_tab = 'studies'
	end
end
