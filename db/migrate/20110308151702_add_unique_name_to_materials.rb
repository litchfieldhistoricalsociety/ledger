class AddUniqueNameToMaterials < ActiveRecord::Migration
  def self.up
    add_column :materials, :original_name, :string

	recs = Material.all
	recs.each { |rec|
		rec.original_name = rec.name
		rec.save!
	}
  end

  def self.down
    remove_column :materials, :original_name
  end
end
