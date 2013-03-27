namespace :solr do

	desc "Recreate all objects in solr index"
	task :recreate  => :environment do
		puts "~~~~~~~~~~~ Recreating the solr index..."
		solr = Searcher.new()
		solr.destroy_all

		print "Students"
		students = Student.all
		students.each_with_index { |student, i|
			solr.add_object_quick(student.to_solr())
			print '.' if i % 50 == 0
		}
		puts ""

		print "Objects"
		materials = Material.all
		materials.each_with_index { |material, i|
			solr.add_object_quick(material.to_solr())
			print '.' if i % 50 == 0
		}
		puts ""
		puts "Committing..."
		solr.commit()
	end
end

namespace :memcache do

	desc "Start memcache"
	task :start do
		puts "Start memcache..."
		puts `memcached -d`
	end

	desc "Continue warming browsing cache"
	task :continue_warming_browsing_cache => [ 'environment' ] do
		Browse.warm()
	end

	desc "Warm browsing cache (invalidate the cache first)"
	task :completely_rewarm => [ 'environment' ] do
		Browse.invalidate()
		Browse.warm()
	end

end

namespace :data do

	def add_unique_name_to_all(model)
		# first clear everything out just to make sure there aren't inconsistencies from earlier runs.
		recs = model.all
		recs.each { |rec|
			rec.name = "#{rec.id}"
			rec.save!
		}

		# regenerate a unique name for each record. If the name is unique, use that, otherwise
		# let the model figure out what the unique name should be.
		# If the model doesn't return a unique name, then arbitrarily add a number to the end.
		recs = model.all
		recs.each_with_index { |rec, i|
			rec.generate_unique_name()
			rec.save!
			print '.' if i % 50 == 0
		}
	end

	desc "Generate Unique Names"
	task :generate_unique_names => [ 'environment' ] do
		print "Modifying students"
		add_unique_name_to_all(Student)
		print "Modifying materials"
		add_unique_name_to_all(Material)
	end

end
