class MaterialMaterial < ActiveRecord::Base
	def self.remove_material(id)
		assocs = MaterialMaterial.find_all_by_material1_id(id)
		assocs.each { |assoc|
			assoc.destroy
		}
		assocs = MaterialMaterial.find_all_by_material2_id(id)
		assocs.each { |assoc|
			assoc.destroy
		}
	end

	def self.factory(id1, id2, description1, description2)
		if id1 < id2
			MaterialMaterial.create({ :material1_id => id1, :material2_id => id2, :description1 => description1, :description2 => description2 })
		else
			MaterialMaterial.create({ :material1_id => id2, :material2_id => id1, :description1 => description2, :description2 => description1 })
		end
	end
end
