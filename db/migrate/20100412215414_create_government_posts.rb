class CreateGovernmentPosts < ActiveRecord::Migration
  def self.up
    create_table :government_posts do |t|
	  t.decimal :student_id
      t.string :which
      t.string :title
      t.string :modifier
      t.string :location
      t.string :time_span

      t.timestamps
    end
  end

  def self.down
    drop_table :government_posts
  end
end
