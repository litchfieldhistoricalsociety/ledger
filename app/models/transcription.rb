class Transcription < ActiveRecord::Base
	has_many :material_transcriptions
	has_many :materials, :through => :material_transcriptions
	include Paperclip
	path = "/transcriptions/:id/:basename.:extension"
	# to create a cropped image, use :thumb=> "100x100#".
	has_attached_file :pdf,
		:url  => path,
		:path => ":rails_root/public/#{path}"
end
