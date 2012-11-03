#!/usr/bin/env ruby
require 'date'
require_relative 'timesheet'

class TimesheetClock

	def initialize(timesheet_filename, delimiter = "\t", rounding_amount = 15*60)
		@timesheet_filename = timesheet_filename
		@delimiter = delimiter
		@rounding_amount = rounding_amount
	end

	def clock_in()
		if self.clocked_in?
			raise "Already clocked in"
		end

		start_timestamp = self.now_rounded()
		start_of_entry = "#{ToS.date(start_timestamp)}#{@delimiter}#{ToS.time(start_timestamp)}#{@delimiter}"
		File.open(@timesheet_filename, 'a') { |f| f.write(start_of_entry) }

		return start_of_entry
	end

	def clock_out(comment)
		last_entry = self.last_entry()
		if !self.clocked_in?(last_entry)
			raise "Not clocked in"
		end

		clocked_in_timestamp = DateTime.parse(last_entry).to_time.to_i
		clocked_out_timestamp = self.now_rounded()
		if clocked_in_timestamp == clocked_out_timestamp
			clocked_out_timestamp += @rounding_amount
		end

		rest_of_entry = "#{ToS.time(clocked_out_timestamp)}#{@delimiter}#{comment}\n"
		File.open(@timesheet_filename, 'a') { |f| f.write(rest_of_entry) }

		return last_entry+rest_of_entry
	end

	def clocked_in?(last_entry = nil)
		if last_entry == nil
			last_entry = self.last_entry()
		end

		return last_entry.count(@delimiter) < 3
	end

	protected
	def last_entry()
		File.open(@timesheet_filename).inject { |_, last_line| last_line }
	end

	def now_rounded()
		now = Time.now.to_i
		now += Time.now.utc_offset # now as if it was utc

		seconds_past_now_floored = now % @rounding_amount
		now_floored = now - seconds_past_now_floored

		return seconds_past_now_floored > @rounding_amount/2 ? now_floored+@rounding_amount : now_floored
	end
	
end
