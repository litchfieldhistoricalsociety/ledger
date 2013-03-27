class CreateTranscriptions < ActiveRecord::Migration
  def self.up
    create_table :transcriptions do |t|
      t.string :pdf_file_name
      t.string :pdf_content_type
      t.string :pdf_file_size
      t.string :pdf_updated_at
	  t.string :title

      t.timestamps
    end
  end

  def self.down
    drop_table :transcriptions
  end
end
