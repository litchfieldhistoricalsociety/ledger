class VagueDate
	# The vague date is held as a string in the database, but it is validated here so that the user's input is consistent and so the
	# date can be successfully understood.
	EARLIEST_YEAR = 1750
	LATEST_YEAR = 1870
	def initialize(bap, ca, ty, mon, day, yr, mon2, day2, yr2)
		@bBaptized = bap	# this means that this record refers to the baptism date, not a birthdate.
		@bCirca = ca	# this means that the entire record or part of it is uncertain in some way.
		@eType = ty	# normal, before, after, between
		@aMonth = mon	# nil is month-uncertain, otherwise an array of months. a single value means the month is certain.
		@aDay = day
		@aYear = yr	# if eType is 'between', then this is expected to be an array of two values.
		@aMonth2 = mon2	# nil is month-uncertain, otherwise an array of months. a single value means the month is certain.
		@aDay2 = day2
		@aYear2 = yr2	# if eType is 'between', then this is expected to be an array of two values.
	end

	def self.translate_month(month_vals, mon, m)
		i = mon.index(m)
		if i == nil
			puts "Illegal value in month: #{m}"
			return "XXX"
		end
		return month_vals[i]
	end

	def self.full(str)
		return "Unknown" if str == nil || str.length == 0
		return str
	end

	def self.year(str)
		return nil if str == nil
		vd = VagueDate.factory(str)
		if vd.kind_of?(VagueDate)
			return vd.get_year()
		else
			return nil
		end
	end

	def self.years(str)
		return nil if str == nil
		vd = VagueDate.factory(str)
		if vd.kind_of?(VagueDate)
			return vd.get_years()
		else
			return nil
		end
	end

	def self.is_between(str, first, last)
		# This returns true if the year represented by the string is at least partially between the two years passed in
		return false if str == nil
		vd = VagueDate.factory(str)
		puts "Not a date: #{str}" if !vd.kind_of?(VagueDate)
		return false if !vd.kind_of?(VagueDate)
		yrs = vd.get_years()
		yrs.each { |yr|
			  return true if first <= yr && yr <= last
		}
		return false
	end

	def self.factory(str)	# pass in a user string, validate it and return a string with an error message or VagueDate object
		months = "January|February|March|April|May|June|July|August|September|October|November|December|Jan\\.|Feb\\.|Mar\\.|Apr\\.|Jun\\.|Jul\\.|Aug\\.|Sep\\.|Oct\\.|Nov\\.|Dec\\.|Jan|Feb|Mar|Apr|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec"
		month_vals = [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 1,2,3,4,6,7,8,9,10,11,12, 1,2,3,4,6,7,8,9,9,10,11,12]
		# this can also be passed in a string that was created with the to_s function, so VagueDate can be reconstructed.
		str = str.strip()
		return nil if str.length == 0 || str == 'unknown' || str == 'uknown' || str == 'Unknown'
		baptized = false
		bapt_match = /Baptised - |Baptized in|baptized in|Baptized|baptized|Baptised|baptised|Bapt\.|aptized/
		if str.match(bapt_match)
			str = str.sub(bapt_match, '')
			baptized = true
		end
		circa_match = /(^c(irc)?a?[. ])|(\?\?)|[Aa]round/
		circa = false
		if str.match(circa_match)
			str = str.sub(circa_match, '')
			circa = true
		end
		str = str.strip()

		yr4 = "1[789]\\d\\d"
		yr1 = "(1[789])?\\d?\\d"
		slash = "((\\s*\\/\\s*)|( or ))"
		dy2 = "\\d\\d?"
		spelled_date = "(#{months})\s+#{dy2},*\s*#{yr4}"
		yr_first = /^(#{yr4})\s*(#{months})\s*(#{dy2})/
		yr_first_2mon = /^(#{yr4})\s*(#{months})\s*-\s*(#{months})/
		dy_first = /^(#{dy2})\s*(#{months})\s*(#{yr4})/
		dy_range = /^(#{months})\s*(#{dy2})\s*-(#{dy2}),\s*(#{yr4})/
		if str.match(/^#{yr4}$/)	# example: 1877
			return VagueDate.new(baptized, circa, 'normal', nil, nil, [str.to_i], nil, nil, nil)
		elsif str.match(/^\d\d\/\d\d\/\d\d\d\d$/)	# example: 12/04/1788
			yr = str[6..9].to_i
			mo = str[0..1].to_i
			dy = str[3..4].to_i
#			yr += 1700 if yr > cutoff
#			yr += 1800 if yr <= cutoff
			return VagueDate.new(baptized, circa, 'normal', [mo], [dy], [yr], nil, nil, nil)
		elsif str.match(/^(#{months})\s*#{dy2}(#{slash}#{dy2})?,\s*#{yr4}(\s*#{slash}\s*#{yr1})?$/)	# example: January 1/3, 1877 or 1878
			mon = months.gsub('\\', '').split('|')
			str2 = str.gsub(/(#{months})/) {|m| "#{translate_month(month_vals, mon, m)}" }
			arr = str2.split(',')	# split into month/day and year(s)
			if arr.length != 2
				return "Error4: '#{str}' '#{str2}'"
			end
			arr1 = arr[0].split(' ')
			 if arr1.length < 2
				return "Error: '#{str}' '#{str2}'"
			 end
			mo = arr1[0].to_i
			dy = arr1[1].to_i
			#TODO: if arr1.length == 3, then there is an alternate day
			arr2 = arr[1].split('/')
			yr = arr2[0].to_i
			 if yr < 1700
				return "Error2: '#{str}' '#{str2}'"
			 end
			if arr2.length == 2
				arr2[0] = arr2[0].strip()
				arr2[1] = arr2[1].strip()
				yr2 = arr2[1]
				yr2 = "#{arr2[0][0..2]}#{yr2}" if yr2.length == 1
				yr2 = "#{arr2[0][0..1]}#{yr2}" if yr2.length == 2
			end
			yr = [yr] if yr2 == nil
			yr = [yr, yr2] if yr2 != nil
			if dy <= 0 || mo <= 0
				return "Error3: '#{str}' '#{str2}'"
			 end
			return VagueDate.new(baptized, circa, 'normal', [mo], [dy], yr, nil, nil, nil)
		elsif str.match(/^#{spelled_date}#{slash}#{spelled_date}/)	# example: January 12, 1866 or June 12, 1866
			mon = months.gsub('\\', '').split('|')
			str2 = str.gsub(/(#{months})/) {|m| "#{translate_month(month_vals, mon, m)}" }
			dates = str2.split(/#{slash}/)
			arr = dates[0].split(',')	# split into month/day and year(s)
			if arr.length < 2
				return "Error4: '#{str}' '#{str2}'"
			end
			arr1 = arr[0].split(' ')
			 if arr1.length < 2
				return "Error: '#{str}' '#{str2}'"
			 end
			mo = arr1[0].to_i
			dy = arr1[1].to_i
			#TODO: if arr1.length == 3, then there is an alternate day
			arr2 = arr[1].split('/')
			yr = arr2[0].to_i
			 if yr < 1700
				return "Error2: '#{str}' '#{str2}'"
			 end
			#TODO: if arr2.length == 2, then there is an alternate year
			if dy <= 0 || mo <= 0
				return "Error3: '#{str}' '#{str2}'"
			 end

			arr = dates[dates.length-1].split(',')	# split into month/day and year(s)
			if arr.length < 2
				return "Error5: '#{str}' '#{str2}'"
			end
			arr1 = arr[0].split(' ')
			 if arr1.length < 2
				return "Error6: '#{str}' '#{str2}'"
			 end
			mo2 = arr1[0].to_i
			dy2 = arr1[1].to_i
			#TODO: if arr1.length == 3, then there is an alternate day
			arr2 = arr[1].split('/')
			yr2 = arr2[0].to_i
			 if yr2 < 1700
				return "Error7: '#{str}' '#{str2}'"
			 end
			#TODO: if arr2.length == 2, then there is an alternate year
			if dy2 <= 0 || mo2 <= 0
				return "Error8: '#{str}' '#{str2}'"
			 end
			return VagueDate.new(baptized, circa, 'normal', [mo], [dy], [yr], [mo2], [dy2], [yr2])
		elsif str.match(yr_first)	# example: 1864 Feb 17
			arr = yr_first.match(str)
			mon = months.gsub('\\', '').split('|')
			mo = month_vals[mon.index(arr[2])]
			yr = arr[1].to_i
			dy = arr[3].to_i
			return VagueDate.new(baptized, circa, 'normal', [mo], [dy], [yr], nil, nil, nil)
		elsif str.match(yr_first_2mon)	# example: 1864 Feb-Mar
			arr = yr_first_2mon.match(str)
			mon = months.gsub('\\', '').split('|')
			mo = month_vals[mon.index(arr[2])]
			mo2 = month_vals[mon.index(arr[3])]
			yr = arr[1].to_i
			return VagueDate.new(baptized, circa, 'between', [mo], nil, [yr], [mo2], nil, [yr])
		elsif str.match(dy_first)	# example: 17 Feb 1797
			arr = dy_first.match(str)
			mon = months.gsub('\\', '').split('|')
			mo = month_vals[mon.index(arr[2])]
			yr = arr[3].to_i
			dy = arr[1].to_i
			return VagueDate.new(baptized, circa, 'normal', [mo], [dy], [yr], nil, nil, nil)
		elsif str.match(dy_range)	# example: January 7-10, 1843
			arr = dy_range.match(str)
			mon = months.gsub('\\', '').split('|')
			mo = month_vals[mon.index(arr[1])]
			dy1 = arr[2].to_i
			dy2 = arr[3].to_i
			yr = arr[4].to_i
			return VagueDate.new(baptized, circa, 'between', [mo], [dy1], [yr], [mo], [dy2], [yr])
		elsif str.match(/^(#{months})\s*(#{slash}\s*(#{months}))?\s*of #{yr4}$/)	# example May of 1877
			mon = months.gsub('\\', '').split('|')
			str = str.sub(/(#{months})/) {|m| "#{translate_month(month_vals, mon, m)}" }
			arr = str.split(' of ')
			mo = arr[0].to_i
			yr = arr[1].to_i
			return VagueDate.new(baptized, circa, 'normal', [mo], nil, [yr], nil, nil, nil)
		elsif str.match(/^(#{months})\s*(#{slash}\s*(#{months}))?\s*#{yr4}$/)	# example May 1877   [or May/June 1877]
			mon = months.gsub('\\', '').split('|')
			str = str.sub(/(#{months})/) {|m| "#{translate_month(month_vals, mon, m)}" }
			arr = str.split(' ')
			mo = arr[0].to_i
			yr = arr[1].to_i
			return VagueDate.new(baptized, circa, 'normal', [mo], nil, [yr], nil, nil, nil)
		elsif str.match(/^(#{months})\s*(#{yr4})\s*#{slash}\s*(#{yr4})$/)	# example May 1877/1887
			arr = /^(#{months})\s*(#{yr4})\s*#{slash}\s*(#{yr4})$/.match(str)
			mon = months.gsub('\\', '').split('|')
			mo = month_vals[mon.index(arr[1])]
			yr = arr[2].to_i
			yr2 = arr[3].to_i
			return VagueDate.new(baptized, circa, 'normal', [mo], nil, [yr], nil, nil, [yr2])
		elsif str.match(/^([Bb]efore|prior to|[Pp]re)\s*#{yr4}$/)	# example Before 1865
			str = str.gsub(/[^\d]/, '')
			yr = str.to_i
			return VagueDate.new(baptized, circa, 'before', nil, nil, [yr], nil, nil, nil)
		elsif str.match(/^([Bb]efore|prior to|[Pp]re)\s*(#{months})\s*(#{yr4})$/)	# example Before November 1865
			arr = /^([Bb]efore|prior to|[Pp]re)\s*(#{months})\s*(#{yr4})$/.match(str)
			mon = months.gsub('\\', '').split('|')
			mo = month_vals[mon.index(arr[2])]
			yr = arr[3].to_i
			return VagueDate.new(baptized, circa, 'before', [mo], nil, [yr], nil, nil, nil)
		elsif str.match(/^([Bb]efore|prior to|[Pp]re)\s*(#{months})\s*(#{dy2}),\s*(#{yr4})$/)	# example Before November 12, 1865
			arr = /^([Bb]efore|prior to|[Pp]re)\s*(#{months})\s*(#{dy2}),\s*(#{yr4})$/.match(str)
			mon = months.gsub('\\', '').split('|')
			mo = month_vals[mon.index(arr[2])]
			dy = arr[3].to_i
			yr = arr[4].to_i
			return VagueDate.new(baptized, circa, 'before', [mo], [dy], [yr], nil, nil, nil)
		elsif str.match(/^[Aa]ft?er #{yr4}$/)
			str = str.gsub(/[^\d]/, '')
			yr = str.to_i
			return VagueDate.new(baptized, circa, 'after', nil, nil, [yr], nil, nil, nil)
		elsif str.match(/^#{yr4} or #{yr4}$/)	#example 1877 or 1878
			arr = str.split(' or ')
			yr = arr[0].to_i
			yr2 = arr[1].to_i
			return VagueDate.new(baptized, circa, 'normal', nil, nil, [yr, yr2], nil, nil, nil)
		elsif str.match(/^#{yr4}#{slash}#{yr1}$/)	# example 1885/1866
			arr = str.split('/')
			arr = str.split(' or ') if arr.length == 1
			yr = arr[0].to_i
			y = arr[1]
			y = arr[0][0..2] + y if y.length == 1
			y = arr[0][0..1] + y if y.length == 2
			yr2 = y.to_i
			return VagueDate.new(baptized, circa, 'normal', nil, nil, [yr, yr2], nil, nil, nil)
		elsif str.match(/^#{yr4}\'?s$/)	#example 1880s
			yr = str.to_i
			return VagueDate.new(baptized, circa, 'between', nil, nil, [yr], nil, nil, [yr+9])
		elsif str.match(/^[Bb]etween (#{yr4}) and (#{yr4})$/)
			arr = /^[Bb]etween (#{yr4}) and (#{yr4})$/.match(str)
			yr = arr[1].to_i
			yr2 = arr[2].to_i
			return VagueDate.new(baptized, circa, 'between', nil, nil, [yr], nil, nil, [yr2])
		elsif str.match(/^#{yr4}-#{yr4}$/)
			yr = str[0..3].to_i
			yr2 = str[5..8].to_i
			return VagueDate.new(baptized, circa, 'between', nil, nil, [yr], nil, nil, [yr2])
		elsif str.match(/^[Bb]etween\s+(#{yr4})\s*-\s*(#{yr4})$/)
			arr = /^[Bb]etween (#{yr4})\s*-\s*(#{yr4})$/.match(str)
			yr = arr[1].to_i
			yr2 = arr[2].to_i
			return VagueDate.new(baptized, circa, 'between', nil, nil, [yr], nil, nil, [yr2])
		elsif str.match(/^(#{months})\s*#{dy2}\s*#{slash}\s*(#{months})\s*#{yr4}$/)	#example January 13/ June 1881
			arr = /^(#{months})\s*(#{dy2})\s*#{slash}\s*(#{months})\s*(#{yr4})$/.match(str)
			#yr = arr[5].to_i
			mon = months.gsub('\\', '').split('|')
			mo = translate_month(month_vals, mon, arr[1])
			dy = arr[2].to_i
			mo2 = translate_month(month_vals, mon, arr[6])
			yr2 = arr[7]
			return VagueDate.new(baptized, circa, 'normal', [mo], [dy], [yr2], [mo2], nil, [yr2])
		elsif str.match(/^(#{months})\s*#{dy2}\s*#{slash}\s*(#{months})\s*#{dy2},\s*#{yr4}$/)	#example February 11/ September 2, 1808
			arr = /^(#{months})\s*(#{dy2})\s*#{slash}\s*(#{months})\s*(#{dy2}),\s*(#{yr4})$/.match(str)
			yr = arr[8].to_i
			mon = months.gsub('\\', '').split('|')
			mo = translate_month(month_vals, mon, arr[1])
			dy = arr[2].to_i
			mo2 = translate_month(month_vals, mon, arr[6])
			dy2 = arr[7]
			return VagueDate.new(baptized, circa, 'normal', [mo], [dy], [yr], [mo2], [dy2], [yr])
		elsif str.match(/^(#{months})\s*#{slash}\s*(#{months})\s*#{dy2}\s*,\s*#{yr4}$/)	#example Jan/ July 23, 1797
			arr = /^(#{months})\s*#{slash}\s*(#{months})\s*(#{dy2})\s*,\s*(#{yr4})$/.match(str)
			yr = arr[7].to_i
			mon = months.gsub('\\', '').split('|')
			mo = translate_month(month_vals, mon, arr[1])
			dy = arr[6].to_i
			mo2 = translate_month(month_vals, mon, arr[5])
			dy2 = arr[6]
			return VagueDate.new(baptized, circa, 'normal', [mo], [dy], [yr], [mo2], [dy2], [yr])
		elsif str.match(/^(#{months})\s*#{dy2}\s*,\s*#{yr4}\s*#{slash}\s*(#{months})\s*#{yr4}$/)	#example February 15, 1796 or September 1797
			arr = /^(#{months})\s*(#{dy2})\s*,\s*(#{yr4})\s*#{slash}\s*(#{months})\s*(#{yr4})$/.match(str)
			yr = arr[3].to_i
			mon = months.gsub('\\', '').split('|')
			mo = translate_month(month_vals, mon, arr[1])
			dy = arr[2].to_i
			mo2 = translate_month(month_vals, mon, arr[7])
			yr2 = arr[8].to_i
			return VagueDate.new(baptized, circa, 'normal', [mo], [dy], [yr], [mo2], nil, [yr2])
		end
		return "Format unrecognizable"
	end

	def format_one_date(m, d, y)
		months = %w{ January February March April May June July August September October November December }
		str = ''
		if m != nil
			mon = []
			m.each {|m2|
				mon.push(months[m2-1])
			}
			str += mon.join(' or ') + ' '
		end
		str += d.join(' or ') + ', ' if d != nil
		str += y.join(' or ') if y != nil
		return str
	end

	def to_s()
		# this prints the complete date record, suitable for displaying and suitable for storing in the database.
		str = ""
		str += "Baptized " if @bBaptized
		str += "ca. " if @bCirca
		str += "#{@eType} " if @eType != "normal"
		if @eType == 'between'
			str += "#{format_one_date(@aMonth, @aDay, @aYear)} and #{format_one_date(@aMonth2, @aDay2, @aYear2)}"
		else
			str += format_one_date(@aMonth, @aDay, @aYear)
			str += " or " + format_one_date(@aMonth2, @aDay2, @aYear2) if @aYear2 != nil
		end
		return str
	end

	def get_year()
		# this returns a string with a single year, for when the year is requested
		if @aYear != nil
			if @aYear2 != nil
				yrs = @aYear + @aYear2
			else
				yrs = @aYear
			end
		else
			if @aYear2 != nil
				yrs = @aYear2
			else
				yrs = []
			end
		end
		return yrs.join(',')
	end

	def get_years()
		# this returns an array of years that this date could meet.
		yrs = []
		if @eType == 'between'
			@aYear[0].upto(@aYear2[0]) { |y|
				yrs.push(y)
			}
		elsif @eType == 'normal'
			if @aYear
				@aYear.each {|y|
					yrs.push(y)
				}
			end
			if @aYear2
				@aYear2.each {|y|
					yrs.push(y)
				}
			end
		elsif @eType == 'before'
			EARLIEST_YEAR.upto(@aYear[0]) { |y|
				yrs.push(y)
			}
		elsif @eType == 'after'
			@aYear[0].upto(LATEST_YEAR) { |y|
				yrs.push(y)
			}
		end
		return yrs
	end
end
