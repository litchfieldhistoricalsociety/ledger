class CreateImages < ActiveRecord::Migration
  def self.up
    create_table :images do |t|
		t.string :photo_file_name
		t.string :photo_content_type
		t.string :photo_file_size
		t.string :photo_updated_at
		t.text :transcription

      t.timestamps
    end
  end

  def self.down
    drop_table :images
  end
end
