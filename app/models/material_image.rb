class MaterialImage < ActiveRecord::Base
	belongs_to :image
	belongs_to :material
end
