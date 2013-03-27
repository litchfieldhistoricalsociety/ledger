namespace :js do
  
  desc "Compress all css and js files"
  task :compress_css_js => :environment do
		# The purpose of this is to roll all our css and js files into one minimized file so that load time on the server is as short as
		# possible. Using this method allows different pages to have different sets of includes, and allows the developer to create
		# as many small css and js files as they want. See get_include_file_list.rb for details.
		compress_file('javascripts', '.js')
		compress_file('stylesheets', '.css')

		concatenate_js()
		concatenate_css()
	end

	def compress_file(folder, ext)
		Dir.foreach("#{Rails.root}/public/#{folder}") { |f|
			if f.index(ext) == f.length - ext.length
				fname = f.slice(0, f.length - ext.length)
				if fname.index('-min') != fname.length - 4
					puts "Compressing #{f}..."
					system("java -jar #{Rails.root}/lib/tasks/yuicompressor-2.4.2.jar --line-break 7000 -o #{Rails.root}/tmp/#{fname}-min#{ext} #{Rails.root}/public/#{folder}/#{f}")
				end
			end
		}
	end

	def concatenate_js()
		list_proto = []
		fnames = GetIncludeFileList.get_js()
		fnames[:prototype].each { |f|
			list_proto.push("#{Rails.root}/tmp/#{f}-min.js")
		}

		list = []
		fnames[:local].each { |f|
			list.push("#{Rails.root}/tmp/#{f}-min.js")
		}

		dest ="javascripts/js-min.js"
		puts "Creating #{dest}..."
		system("cat #{list_proto.join(' ')} > #{Rails.root}/public/javascripts/prototype-min.js")
		system("cat #{list.join(' ')} > #{Rails.root}/public/#{dest}")
	end

	def concatenate_css()
		list = []
		fnames = GetIncludeFileList.get_css()
		fnames[:local].each { |f|
			list.push("#{Rails.root}/tmp/#{f}-min.css")
		}
		dest ="stylesheets/css-min.css"
		list = list.join(' ')
		puts "Creating #{dest}..."
		system("cat #{list} > #{Rails.root}/public/#{dest}")
	end

	# This gets all the files in the folder tree with the passed extension, but not any files with skip_ext, and not the files in the exception_list
	def get_file_list(folder, ext, skip_ext, exception_list)
		list = []
		Dir.foreach(folder) { |f|
			if f != '.' && f != '..'
				if File.stat("#{folder}/#{f}").directory?
					list += get_file_list("#{folder}/#{f}", ext, skip_ext, exception_list)
				elsif f.index(ext) == f.length - ext.length && f.index(skip_ext) != f.length - skip_ext.length
					list.push("#{folder}/#{f}") if !exception_list.include?(f)
				end
			end
		}
		return list
	end

  desc "Run JSLint on all js files"
  task :jslint => :environment do
		list = get_file_list("#{Rails.root}/public/javascripts", '.js', '-min.js', [ 'prototype.js', 'controls.js', 'effects.js', 'dragdrop.js', 'rails.js' ])
		list.each { |f|
			puts "Linting #{f}..."
			system("java -jar #{Rails.root}/lib/tasks/rhino1_7R2_js.jar #{Rails.root}/lib/tasks/fulljslint.js #{f}")
		}
	end
end

