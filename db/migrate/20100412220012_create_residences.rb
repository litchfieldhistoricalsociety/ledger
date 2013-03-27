class CreateResidences < ActiveRecord::Migration
  def self.up
    create_table :residences do |t|
      t.string :town
      t.string :state
      t.string :country

      t.timestamps
    end
  end

  def self.down
    drop_table :residences
  end
end
