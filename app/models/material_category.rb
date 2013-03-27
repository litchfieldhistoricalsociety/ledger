class MaterialCategory < ActiveRecord::Base
	belongs_to :material
	belongs_to :category

	def self.add_connection(material_id, category_id)
		self.create({ :material_id  => material_id, :category_id => category_id })
	end

	def self.add(material_id, category_name)
		category = Category.find_by_title(category_name)
		if category == nil
			category = Category.create({:title => category_name})
		end
		self.add_connection(material_id, category.id)
	end

	def self.remove_material(material_id)
		recs = MaterialCategory.find_all_by_material_id(material_id)
		recs.each { |rec|
			id = rec.category_id
			rec.destroy()
			other = MaterialCategory.find_by_category_id(id)
			if other == nil # we've deleted the last one
				other = Category.find(id)
				other.destroy
			end
		}
	end
end
