class CreateMaterialTranscriptions < ActiveRecord::Migration
  def self.up
    create_table :material_transcriptions do |t|
      t.decimal :material_id
      t.decimal :transcription_id

      t.timestamps
    end
  end

  def self.down
    drop_table :material_transcriptions
  end
end
