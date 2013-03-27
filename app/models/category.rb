class Category < ActiveRecord::Base
	has_many :material_categories
	has_many :materials, :through => :material_categories
end
