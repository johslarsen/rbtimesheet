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
		Time.at(utime).utc.strftime("%Y-%m-%d")
	end

	def self.time(utime)
		Time.at(utime).utc.strftime("%H:%M")
	end

	def self.duration(seconds)
		"%5d:%02d" % (seconds/SECONDS_IN_A_MINUTE).divmod(MINUTES_IN_AN_HOUR)
	end

	def self.value(n)
		"%.2f" % n
	end

end

class Entry

	include Comparable

	attr_reader :from
	attr_reader :to
	attr_reader :comment

	def initialize(from, to, comment)
		@from = from.to_i
		@to = to.to_i
		@comment = comment.to_s

		raise ArgumentError, "from must be before to" unless @from < @to
		raise ArgumentError, "from and to must be on the same day" unless @to < self.midnight+SECONDS_IN_A_DAY
		raise ArgumentError, "Require non-empty comment" unless !@comment.empty?
	end

	def to_s
		[ToS.date(@from), ToS.time(@from), ToS.time(@to), ToS.duration(self.duration), @comment].join(" ")
	end

	def midnight
		@from - (@from%SECONDS_IN_A_DAY)
	end

	def duration(limit_from=nil, limit_to=nil)
		duration = [@to, limit_to].compact.min - [@from, limit_from].compact.max
		duration>0 ? duration : 0
	end

	def <=>(other)
		@from <=> other.from
	end
end

class Timesheet


	include Comparable
	include Enumerable

	attr_reader :entries
	attr_reader :metadata

	def initialize(metadata, entries)
		@metadata = metadata.clone
		@entries = entries.sort

		raise ArgumentError, "entries must be non-empty" unless !entries.empty?
	end

	RATE_KEY = "rate"
	def rate
		@metadata[RATE_KEY]
	end

	def rate?
		@metadata.has_key?(RATE_KEY)
	end

	RATE_CURRENCY_KEY = "rate_currency"
	def rate_currency
		@metadata[RATE_CURRENCY_KEY]
	end

	def rate_currency?
		@metadata.has_key?(RATE_CURRENCY_KEY)
	end

	def duration
		@entries.inject(0) { |memo, obj| memo + obj.duration }
	end

	def from
		@entries[0].from
	end

	def to
		@entries[-1].to
	end

	def value
		self.rate? ? self.duration*(self.rate.to_f/SECONDS_IN_AN_HOUR) : nil
	end

	def <=>(other)
		self.from <=> other.from
	end

	def each
		@entries.each do |i|
			yield i
		end
	end

	def to_s
		self.summary
	end

	def summary
		currency = ""
		rate_unit = ""
		if self.rate_currency?
			currency = "[#{self.rate_currency}]"
			rate_unit = "[#{currency[1..-2]}/Hour]"
		end

		rate_and_value = "* %d%s = %s%s" % [self.rate, rate_unit, ToS.value(self.value), currency]

		[ToS.date(self.from), "---", ToS.date(self.to), ToS.duration(self.duration), rate_and_value].join(" ")
	end


	def sum_by_hour
		([nil]*HOURS_IN_A_DAY).each_with_index.map do |n, i|
			@entries.inject(0) do |sum, obj; midnight|
				midnight = obj.midnight
				sum += obj.duration(midnight + i*SECONDS_IN_AN_HOUR, midnight + (i+1)*SECONDS_IN_AN_HOUR)
			end
		end
	end

	def sum_by_date
		dates = Hash.new(0)
		@entries.each { |entry| dates[ToS.date(entry.from)] += entry.duration }
		return dates
	end

	def sum_by_weekday
		weekdays = [0]*DAYS_IN_A_WEEK
		@entries.each { |entry| weekdays[Time.at(entry.from).wday] += entry.duration }
		return weekdays
	end

	def sum_by_week
		weeks = [0]*WEEKS_IN_A_YEAR
		@entries.each { |entry| weeks[Time.at(entry.from).strftime("%W").to_i] += entry.duration }
		return weeks
	end
end
