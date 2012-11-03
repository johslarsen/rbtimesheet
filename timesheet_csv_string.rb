#!/usr/bin/env ruby

require 'date'
require 'json'
require_relative 'timesheet'

class TimesheetCSVString < Timesheet

	FIELD_DATE       = 0
	FIELD_TIME_START = 1
	FIELD_TIME_END   = 2
	FIELD_COMMENT    = 3..-1

	COMMENT_CHAR = "#"
	TIME_DELIMITER = ":"

	def initialize(csv, delimiter = "\t")
		@metadata = {}
		@entries = []

		csv.split("\n").each do |row|
			next if row.empty?

			if row[0] == COMMENT_CHAR
				self.parse_comment(row[1..-1])
			else
				self.parse_entry(row, delimiter)
			end
		end

		super(@metadata, @entries)
	end

	def parse_comment(comment)
		key, delimiter, value = comment.partition("=")
		if !delimiter.empty?
			@metadata[key.strip] = JSON.parse("["+value.strip+"]")[0]
		end
	end

	def parse_date(date)
		DateTime.parse(date).to_time.to_i
	end

	def parse_time(time)
		fields = time.split(TIME_DELIMITER)

		raise "Cannot parse '#{time}' as a time of day" if 1 > fields.length || fields.length > 3

		seconds = 0
		seconds += fields.pop.to_f                       if fields.length == 3
		seconds += fields.pop.to_f * SECONDS_IN_A_MINUTE if fields.length == 2

		return seconds + fields.pop.to_f * SECONDS_IN_AN_HOUR
	end

	def parse_entry(entry, delimiter)
		fields = entry.split(delimiter)

		midnight = self.parse_date(fields[FIELD_DATE])
		start_after_midnight = self.parse_time(fields[FIELD_TIME_START])
		end_after_midnight = self.parse_time(fields[FIELD_TIME_END])
		comment = fields[FIELD_COMMENT].join(delimiter)

		utime_start = midnight+start_after_midnight
		while end_after_midnight > 0 do
			utime_end = midnight + (end_after_midnight < SECONDS_IN_A_DAY ? end_after_midnight : SECONDS_IN_A_DAY)
			@entries.push(Entry.new(utime_start, utime_end, comment))

			utime_start = midnight = utime_end
			end_after_midnight -= SECONDS_IN_A_DAY
		end
	end

end
