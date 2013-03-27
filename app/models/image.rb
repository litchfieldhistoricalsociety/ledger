class Image < ActiveRecord::Base
	has_many :material_images
	has_many :materials, :through => :material_images
	include Paperclip
	path = "objects/:id/:style/:basename.:extension"
	# to create a cropped image, use :thumb=> "100x100#".
	has_attached_file :photo, :styles => { :thumb=> "150x150>", :small  => "300x300>" },
		:url  => path,
		:path => ":rails_root/public/#{path}"
end
