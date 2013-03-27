class StudentMaterial < ActiveRecord::Base
	belongs_to :student
	belongs_to :material

	def self.remove_material(material_id)
		recs = StudentMaterial.find_all_by_material_id(material_id)
		recs.each { |rec| rec.destroy() }
	end

	def self.remove_student(student_id)
		recs = StudentMaterial.find_all_by_student_id(student_id)
		recs.each { |rec| rec.destroy() }
	end
end
