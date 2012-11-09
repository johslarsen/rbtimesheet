#!/usr/bin/env ruby
require_relative 'common'

module Timesheet
	class AsciiTables
		def initialize(timesheet)
			@timesheet = timesheet
		end

		def entries()
			@timesheet.map {|o| o}.join("\n")
		end

		def metadata()
			longest_key = @timesheet.metadata.each_key.inject { |memo, key| key.length > memo.length ? key : memo }

			@timesheet.metadata.inject("") do |table, key_value; key, value|
				key, value = key_value
				"%s%-*s = %s\n" % [table, longest_key.length, key, value]
			end
		end

		def summary()
			@timesheet.summary()
		end

		def sum_by_hour(skip_empty = true)
			@timesheet.sum_by_hour.each_with_index.inject("") do |table, duration_and_hour; duration, hour|
				duration, hour = duration_and_hour
				skip_empty && duration==0 ? table : "%s%02d:00 %s\n" % [table, hour, Timesheet.to_s_duration(duration)]
			end
		end

		def sum_by_weekday(skip_empty = true)
			start_of_week = Time.now.to_i - (Time.now.to_i%SECONDS_IN_A_WEEK)

			@timesheet.sum_by_weekday.each_with_index.inject("") do |table, duration_and_weekday; duration, weekday|
				duration, weekday = duration_and_weekday
				skip_empty && duration==0 ? table : "%s%-9s %s\n" % [table, Time.at(start_of_week+weekday*Timesheet::SECONDS_IN_A_DAY).strftime("%A"), Timesheet.to_s_duration(duration)]
			end
		end

		def sum_by_week(skip_empty = true)
			@timesheet.sum_by_week.each_with_index.inject("") do |table, duration_and_weeknumber; duration, weeknumber|
				duration, weeknumber = duration_and_weeknumber
				skip_empty && duration == 0 ? table : "%s%02d %s\n" % [table, weeknumber, Timesheet.to_s_duration(duration)]
			end
		end

		def sum_by_date
			@timesheet.sum_by_date.inject("") do |table, date_and_duration; date, duration|
				date, duration = date_and_duration
				"%s%s %s\n" % [table, date, Timesheet.to_s_duration(duration)]
			end
		end
	end
end
