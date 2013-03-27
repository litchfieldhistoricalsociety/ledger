class AttendedYear < ActiveRecord::Base
	def self.to_friendly_string(recs)
		# This takes an array of AttendedYear records and combines them into a format that is easy to read.
		recs = recs.sort { |a,b| a.year <=> b.year }
		yrs = []
		comment = ""
		recs.each {|rec|
			comment = rec.comment if comment.length == 0 && rec.comment && rec.comment.length > 0
			if yrs.length == 0
				yrs.push({ :start => rec.year, :end => rec.year })
			else
				if yrs[yrs.length-1][:end] == rec.year-1
					yrs[yrs.length-1][:end] = rec.year
				else
					yrs.push({ :start => rec.year, :end => rec.year })
				end
			end
		}
		yrs.collect! { |yr|
			if yr[:start] == yr[:end]
				yr[:start]
			else
				"#{yr[:start]}-#{yr[:end]}"
			end
		}
		if yrs.length == 1 && yrs[0] == 0
			yrs = []
		end
		return "#{comment}#{yrs.join(',')}"
	end

	def self.to_school_year_string(recs)
		lls = []
		lfa = []
		recs.each { |rec|
			if rec.school == 'LLS'
				lls.push(rec)
			else
				lfa.push(rec)
			end
		}
		str = ""
		if lls.length > 0
			str += ' LLS (' + AttendedYear.to_friendly_string(lls) + ')'
		end
		if lfa.length > 0
			str += ' LFA (' + AttendedYear.to_friendly_string(lfa) + ')'
		end
		return str
	end

	def self.to_year_array(str)
		arr = str.split(',')
		ret = []
		arr.each {|a|
			a2 = a.split('-')
			if a2.length == 1
				ret.push(a)
			else
				a2[0].to_i.upto(a2[1].to_i) { |i|
					ret.push(i)
				}
			end
		}
		return ret
	end

	def self.to_school_string(recs)
		schools = {	}
		recs.each {|rec|
			schools[rec.school] = true
		}
		schools = schools.keys()
		return schools.join(",")
	end

	def self.parse_year_string(str)
		output = []
		str = str.sub("(was she just a teacher or was she a student too??)", "")
		str = str.sub("student", "")
		str = str.gsub(' -', '-')
		str = str.gsub('- ', '-')
		is_or = str.match(/or/)
		if is_or
			str = str.sub(' or ', ',')
			is_circa = true
		end
		is_pre2 = str.match(/Sometime prior to/)
		str = str.sub(/Sometime prior to/, '') if is_pre2
		str = str.gsub(' ', ',')
		str = str.gsub('/', ',')
		is_unconfirmed = str.match(/\(?unconfirmed\)?/)
		str = str.sub(/\(?unconfirmed\)?/, '') if is_unconfirmed
		is_unconfirmed2 = str.match(/\?/)
		str = str.gsub(/\?/, '') if is_unconfirmed2
		is_unconfirmed = is_unconfirmed || is_unconfirmed2
		is_circa = str.match(/^circa|^c\.|^ca\.|^ca|^c/)
		str = str.sub(/^circa|^c\.|^ca\.|^ca|^c/, '') if is_circa
		is_pre = str.match(/^[Pp]re\-/)
		str = str.sub(/^[Pp]re\-/, '') if is_pre
		is_pre = is_pre || is_pre2
		is_post = str.match(/^post\-/)
		str = str.sub(/^post\-/, '') if is_post

		arr = str.split(',')
		arr.each {|substr|
			if substr.length > 0
				is_year = substr.match(/^\d\d\d\d$/)
				is_year_range = substr.match(/^\d\d\d\d\-\d\d\d\d$/)
				is_year_range2 = substr.match(/^\d\d\d\d\-\d\d$/)
				is_year_range3 = substr.match(/^\d\d\d\d\-\d\d\d$/)
				is_decade = substr.match(/^\d\d\d\ds$/) || substr.match(/^\d\d\d\d\'s$/)
				if is_year
					output.push(substr.to_i)
				elsif is_year_range
					range = substr.split("-")
					range[0].to_i.upto(range[1].to_i) { |x|
						output.push(x)
					}
				elsif is_year_range2
					range = substr.split("-")
					range[1] = range[0][0..1] + range[1]
					range[0].to_i.upto(range[1].to_i) { |x|
						output.push(x)
					}
				elsif is_year_range3
					# this just compensates for a typo
					range = substr.split("-")
					range[1] = range[0][0..1] + range[1][1..2]
					range[0].to_i.upto(range[1].to_i) { |x|
						output.push(x)
					}
				elsif is_decade
					start = substr.to_i
					start.upto(start+9) { |x|
						output.push(x)
					}
					is_circa = true
				else
					return nil
				end
			end
		}
		comment = ""
		comment = '(unconfirmed)' if is_unconfirmed
		comment = 'c.' if is_circa
		comment = 'pre-' if is_pre
		comment = 'post-' if is_post
		output.push(0) if is_unconfirmed && output.length == 0
		return { :comment => comment, :years => output }
	end

	def self.add(student_id, school, years)
		if years == "Unknown"
			AttendedYear.create({ :student_id => student_id, :year => 0, :school => school, :comment => years })
			return
		end
		year_hash = self.parse_year_string(years)
		if year_hash[:years].length > 0
			year_hash[:years].each { |y|
				AttendedYear.create({ :student_id => student_id, :year => y, :school => school, :comment => year_hash[:comment] })
			}
		end
	end

	def self.validate_attended(attended, years, act_rec)
		return true if attended == nil
		if years == nil || years.length == 0
			act_rec.errors.add(:attended_year, "Must contain a year if the student has attended. Use \"Unknown\" if the year is not known.")
			return false
		end
		# years can be a 4-digit number, or a list of 4-digit numbers separated by commas and dashes,
		# and, if a single 4-digit number can be preceeded by pre- post- or c.
		# if two numbers have a dash between them, then they must be increasing.
		yr4 = "1[78]\\d\\d"
		before = "(pre-|post-|c\.)"
		connector = "(-|,)"
		return true if years == "Unknown"
		return true if years.match(/^\s*#{yr4}\s*$/)	# example: 1877
		return true if years.match(/^\s*#{before}\s*#{yr4}\s*$/)	# example: pre-1877
		return true if years.match(/^\s*#{yr4}\s*(#{connector}\s*#{yr4}\s*)*\s*$/)	# example: 1875-1877, 1879
		act_rec.errors.add(:attended_year, "Unknown format: must be 4 digit year, optionally with pre-, post-, or c., or a list separated by commas, or a range separated by a dash")
		return false
	end

	def self.remove_student(student_id)
		recs = AttendedYear.find_all_by_student_id(student_id)
		recs.each { |rec|
			rec.destroy()
		}
	end
end
