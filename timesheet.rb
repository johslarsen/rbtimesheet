#!/usr/bin/env ruby

SECONDS_IN_A_MINUTE = 60
MINUTES_IN_AN_HOUR  = 60
HOURS_IN_A_DAY      = 24
DAYS_IN_A_WEEK      = 7
WEEKS_IN_A_YEAR     = 53

SECONDS_IN_AN_HOUR = SECONDS_IN_A_MINUTE * MINUTES_IN_AN_HOUR
SECONDS_IN_A_DAY = SECONDS_IN_AN_HOUR * HOURS_IN_A_DAY
SECONDS_IN_A_WEEK = SECONDS_IN_A_DAY * DAYS_IN_A_WEEK

class ToS
	def self.date(utime)
		return Time.at(utime).utc.strftime("%Y-%m-%d")
	end

	def self.time(utime)
		return Time.at(utime).utc.strftime("%H:%M")
	end

	def self.duration(seconds)
		return "%5d:%02d" % (seconds/SECONDS_IN_A_MINUTE).divmod(MINUTES_IN_AN_HOUR)
	end

	def self.value(n)
		return "%.2f" % n
	end
end

class Entry

	attr_reader :start
	attr_reader :end
	attr_reader :comment

	def initialize(utime_start, utime_end, comment)
		@start = utime_start
		@end = utime_end
		@comment = comment
	end

	def to_s()
		return [ToS.date(@start), ToS.time(@start), ToS.time(@end), ToS.duration(self.duration()), @comment].join(" ")
	end

	def midnight()
		return @start - (@start%SECONDS_IN_A_DAY)
	end

	def duration(limit_start=nil, limit_end=nil)
		utime_start = limit_start ? [@start, limit_start].max : @start
		utime_end = limit_end ? [@end, limit_end].min : @end

		duration = utime_end-utime_start
		return duration>0 ? duration : 0
	end
end

class Timesheet

	RATE_KEY = "rate"
	RATE_CURRENCY_KEY = "rate_currency"

	attr_reader :entries
	attr_reader :metadata

	def initialize(metadata, entries)
		@metadata = metadata
		@entries = entries.sort { |a, b|
			a.start <=> b.start
		}
	end

	def rate()
		return @metadata[RATE_KEY]
	end

	def rate?()
		return @metadata.has_key?(RATE_KEY)
	end

	def rate_currency()
		return @metadata[RATE_CURRENCY_KEY]
	end

	def rate_currency?()
		return @metadata.has_key?(RATE_CURRENCY_KEY)
	end

	def duration()
		return @entries.inject(0) { |memo, obj|
			memo + obj.duration()
		}
	end

	def start
		return @entries[0].start
	end

	def end
		return @entries[-1].end
	end

	def value()
		return self.rate? ? self.duration()*(self.rate().to_f/SECONDS_IN_AN_HOUR) : nil
	end

	def sum_by_hour()
		return ([nil]*HOURS_IN_A_DAY).each_with_index.map { |n, i|
			@entries.inject(0) { |sum, obj|
				midnight = obj.midnight()
				sum += obj.duration(midnight + i*SECONDS_IN_AN_HOUR, midnight + (i+1)*SECONDS_IN_AN_HOUR)
			}
		}
	end

	def sum_by_date_str()
		dates = {}

		@entries.each { |entry|
			date_str = ToS.date(entry.start)
			dates[date_str] = dates[date_str].to_i + entry.duration()
		}

		return dates
	end

	def sum_by_weekday()
		weekdays = [0]*DAYS_IN_A_WEEK

		@entries.each { |entry|
			weekdays[Time.at(entry.start).wday] += entry.duration()
		}

		return weekdays
	end

	def sum_by_week()
		weeks = [0]*WEEKS_IN_A_YEAR

		@entries.each { |entry|
			weeks[Time.at(entry.start).strftime("%W").to_i] += entry.duration()
		}

		return weeks
	end

end
