# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110308151702) do

  create_table "attended_years", :force => true do |t|
    t.decimal  "student_id", :precision => 10, :scale => 0
    t.string   "school"
    t.decimal  "year",       :precision => 10, :scale => 0
    t.string   "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "attended_years", ["student_id"], :name => "index_attended_years_on_student_id"

  create_table "categories", :force => true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "government_posts", :force => true do |t|
    t.decimal  "student_id", :precision => 10, :scale => 0
    t.string   "which"
    t.string   "title"
    t.string   "modifier"
    t.string   "location"
    t.string   "time_span"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "government_posts", ["student_id"], :name => "index_government_posts_on_student_id"

  create_table "images", :force => true do |t|
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.string   "photo_file_size"
    t.string   "photo_updated_at"
    t.text     "transcription"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "marriages", :force => true do |t|
    t.decimal  "student_id",    :precision => 10, :scale => 0
    t.string   "marriage_date"
    t.decimal  "spouse_id",     :precision => 10, :scale => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "marriages", ["spouse_id"], :name => "index_marriages_on_spouse_id"
  add_index "marriages", ["student_id"], :name => "index_marriages_on_student_id"

  create_table "material_categories", :force => true do |t|
    t.decimal  "material_id", :precision => 10, :scale => 0
    t.decimal  "category_id", :precision => 10, :scale => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "material_categories", ["category_id"], :name => "index_material_categories_on_category_id"
  add_index "material_categories", ["material_id"], :name => "index_material_categories_on_material_id"

  create_table "material_images", :force => true do |t|
    t.decimal  "material_id", :precision => 10, :scale => 0
    t.decimal  "image_id",    :precision => 10, :scale => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "material_images", ["image_id"], :name => "index_material_images_on_image_id"
  add_index "material_images", ["material_id"], :name => "index_material_images_on_material_id"

  create_table "material_materials", :force => true do |t|
    t.decimal  "material1_id", :precision => 10, :scale => 0
    t.decimal  "material2_id", :precision => 10, :scale => 0
    t.string   "description1"
    t.string   "description2"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "material_transcriptions", :force => true do |t|
    t.decimal  "material_id",      :precision => 10, :scale => 0
    t.decimal  "transcription_id", :precision => 10, :scale => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "material_transcriptions", ["material_id"], :name => "index_material_transcriptions_on_material_id"
  add_index "material_transcriptions", ["transcription_id"], :name => "index_material_transcriptions_on_transcription_id"

  create_table "materials", :force => true do |t|
    t.string   "name"
    t.string   "object_id"
    t.string   "accession_num"
    t.string   "url"
    t.string   "author"
    t.string   "material_date"
    t.string   "collection"
    t.string   "held_at"
    t.string   "associated_place"
    t.string   "medium"
    t.string   "size"
    t.text     "description"
    t.text     "private_notes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "original_name"
  end

  create_table "offsite_materials", :force => true do |t|
    t.string   "name"
    t.string   "url"
    t.decimal  "student_id", :precision => 10, :scale => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "offsite_materials", ["student_id"], :name => "index_offsite_materials_on_student_id"

  create_table "political_parties", :force => true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "professions", :force => true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "relations", :force => true do |t|
    t.decimal  "student1_id",  :precision => 10, :scale => 0
    t.decimal  "student2_id",  :precision => 10, :scale => 0
    t.string   "relationship"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "relations", ["student1_id"], :name => "index_relations_on_student1_id"
  add_index "relations", ["student2_id"], :name => "index_relations_on_student2_id"

  create_table "residences", :force => true do |t|
    t.string   "town"
    t.string   "state"
    t.string   "country"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "student_materials", :force => true do |t|
    t.decimal  "student_id",       :precision => 10, :scale => 0
    t.decimal  "material_id",      :precision => 10, :scale => 0
    t.string   "relationship"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "material_comment"
  end

  add_index "student_materials", ["material_id"], :name => "index_student_materials_on_material_id"
  add_index "student_materials", ["student_id"], :name => "index_student_materials_on_student_id"

  create_table "student_political_parties", :force => true do |t|
    t.decimal  "student_id",         :precision => 10, :scale => 0
    t.decimal  "political_party_id", :precision => 10, :scale => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "student_political_parties", ["political_party_id"], :name => "index_student_political_parties_on_political_party_id"
  add_index "student_political_parties", ["student_id"], :name => "index_student_political_parties_on_student_id"

  create_table "student_professions", :force => true do |t|
    t.decimal  "student_id",    :precision => 10, :scale => 0
    t.decimal  "profession_id", :precision => 10, :scale => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "student_professions", ["profession_id"], :name => "index_student_professions_on_profession_id"
  add_index "student_professions", ["student_id"], :name => "index_student_professions_on_student_id"

  create_table "student_residences", :force => true do |t|
    t.decimal  "student_id",   :precision => 10, :scale => 0
    t.decimal  "residence_id", :precision => 10, :scale => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "student_residences", ["residence_id"], :name => "index_student_residences_on_residence_id"
  add_index "student_residences", ["student_id"], :name => "index_student_residences_on_student_id"

  create_table "students", :force => true do |t|
    t.string   "name"
    t.string   "sort_name"
    t.string   "other_name"
    t.string   "gender"
    t.text     "room_and_board"
    t.string   "home_town"
    t.string   "home_state"
    t.string   "home_country"
    t.string   "born"
    t.string   "died"
    t.text     "other_education"
    t.string   "admitted_to_bar"
    t.text     "training_with_other_lawyers"
    t.text     "federal_committees"
    t.text     "state_committees"
    t.text     "biographical_notes"
    t.text     "citation_of_attendance"
    t.decimal  "image_id",                                :precision => 10, :scale => 0
    t.text     "secondary_sources"
    t.text     "additional_notes"
    t.text     "private_notes"
    t.text     "benevolent_and_charitable_organizations"
    t.string   "is_stub"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "quotes"
    t.string   "original_name"
  end

  create_table "transcriptions", :force => true do |t|
    t.string   "pdf_file_name"
    t.string   "pdf_content_type"
    t.string   "pdf_file_size"
    t.string   "pdf_updated_at"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "permissions"
    t.string   "email",                               :default => "", :null => false
    t.string   "encrypted_password",   :limit => 128, :default => "", :null => false
    t.string   "password_salt",                       :default => "", :null => false
    t.string   "reset_password_token"
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                       :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
