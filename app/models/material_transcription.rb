class MaterialTranscription < ActiveRecord::Base
	belongs_to :transcription
	belongs_to :material
end
