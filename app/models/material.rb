class Material < ActiveRecord::Base
	has_many :material_images
	has_many :images, :through => :material_images
	has_many :material_transcriptions
	has_many :transcriptions, :through => :material_transcriptions
	has_many :student_materials
	has_many :students, :through => :student_materials
	has_many :material_categories
	has_many :categories, :through => :material_categories

	validates :name, :presence => true
	validate :legal_number?
	validate :legal_date?
	validate :legal_viewing_aid?

	def legal_number?
		if object_id.blank? && accession_num.blank?
			errors.add(:id, "You must specify either an Object Id or an Accession Number")
		end
	end

	def legal_viewing_aid?
		errors.add(:viewing_aid, "Online viewing aid field must be a url starting with http://") if url && url.length > 0 && url.index('http://') != 0
	end

	def legal_date?
		if material_date && material_date.length > 0
			d = VagueDate.factory(material_date)
			errors.add(:date, d) if d.kind_of?(String)
		end
	end

#	include Paperclip
#	path = "/transcriptions/:id/:basename.:extension"
#	has_attached_file :transcription,
#		:url  => path,
#		:path => ":rails_root/public/#{path}"
#	validates_attachment_content_type(:transcription, { :content_type => ['application/pdf'] })

	def to_solr()
		categories = []
		self.categories.each { |rec|
			categories.push(rec.title)
		}

		solr = { :id => self.id,
			:doc_type => 'material',
			:name => self.name,
			:ac_name => self.name,
			:object_id => self.object_id,
			:accession_num => self.accession_num,
			:category => categories,
			:author => self.author,
			:material_date => VagueDate.year(self.material_date),
			:collection => self.collection,
			:held_at => self.held_at,
			:medium => self.medium,
			:size => self.size,
			:description => self.description
		}
		return solr
	end

	def generate_unique_name()
		others = Material.find_all_by_original_name(self.original_name)
		if others.length == 0 || (others.length == 1 && others[0].id == self.id)
			self.name = self.original_name
			return false
		end

		# use either object_id or accession_num, plus material_date if it exists
		append = ''
#		if self.accession_num && self.accession_num.length > 0
#			append = self.accession_num
#		elsif self.object_id && self.object_id.length > 0
#			append = self.object_id
#		end
		if self.material_date && self.material_date.length > 0
			append += "- #{self.material_date}"
		elsif self.author && self.author.length > 0
			append += "by #{self.author}"
		end

		self.name = "#{self.original_name} #{append}"

		# now be sure that it is unique
		matches = Material.find_all_by_name(self.name)
		index = 2
		ideal_unique_name = self.name
		while matches.length > 1 || (matches.length == 1 && matches[0].id != self.id)
			self.name = "#{ideal_unique_name} ##{index}"
			index += 1
			matches = Material.find_all_by_name(self.name)
		end
		return true
	end

	def fill_record()
	end

	def self.convert_solr_response(doc)
		if doc['doc_type'] == 'material'
			arr = doc['id'].split('_')
			if arr.length == 2 && arr[0] == 'material'
				rec = Material.find_by_id(arr[1])
				if rec != nil
					rec.fill_record()
					return rec
				else
					puts "Solr returned a material record that is not in the database: #{doc['name']}"
				end
			else
				puts "Solr returned a record of type #{arr[0]} when expecting a material: #{doc['name']}"
			end
		else
			puts "Solr returned a record of type #{doc['doc_type']} when expecting a material: #{doc['name']}"
		end
		return nil
	end
	
	def self.create_query_string(params)
		arr = []
		arr.push("doc_type:material")
		if params[:q] && params[:q].length > 0
			a = params[:q].split(' ')
			arr.push(a.join(' AND '))
		end
		if params[:repository] && params[:repository].length > 0
			arr.push( "held_at:#{params[:repository]}")
		end
		if params[:category] && params[:category].length > 0
			arr.push( "category:#{params[:category]}")
		end
		str = Student.assemble_date_query_string(params, 'material_date', :date_type, :date_first, :date_second)
		arr.push(str) if str
		return arr.join(' AND ')
	end

#	def self.validate_all(fields)
#		errors = []
#		errors.push("Name must not be blank") if fields['name'] == nil || fields['name'].length == 0
#		if fields['material_date'] && fields['material_date'].length > 0
#			d = VagueDate.factory(fields[:material_date])
#			errors.push("Date: #{d}") if d.kind_of?(String)
#		end
#		errors.push("Online viewing aid field must be a url starting with http://") if fields['url'] && fields['url'].length > 0 && fields['url'].index('http://') != 0
#		# todo: transcription and images is a file object
#		return errors
#	end

	def remove_references()
		# This removes all the other entries in other tables for this material
		recs = MaterialImage.find_all_by_material_id(self.id)
		recs.each { |rec|
			other = Image.find(rec.image_id)
			other.destroy
			rec.destroy()
		}
		recs = MaterialTranscription.find_all_by_material_id(self.id)
		recs.each { |rec|
			other = Transcription.find(rec.transcription_id)
			other.destroy
			rec.destroy()
		}
		StudentMaterial.remove_material(self.id)

		MaterialCategory.remove_material(self.id)
	end
end
