#!/usr/bin/env ruby
require 'date'
require_relative 'timesheet'

class TimesheetClock

	SEEK_STEP = 256

	def initialize(timesheet_filename, delimiter="\t", comment_char="#", rounding_amount=15*60)
		@timesheet_filename = timesheet_filename
		@delimiter = delimiter
		@comment_char = comment_char
		@rounding_amount = rounding_amount
	end

	def clock_in()
		if self.clocked_in?
			raise "Already clocked in"
		end

		from = self.now_rounded()
		start_of_entry = "#{ToS.date(from)}#{@delimiter}#{ToS.time(from)}#{@delimiter}"
		File.open(@timesheet_filename, 'a') { |f| f.write(start_of_entry) }

		return start_of_entry
	end

	def clock_out(comment)
		last_entry = self.last_entry()
		if !self.clocked_in?(last_entry)
			raise "Not clocked in"
		elsif last_entry[-1] != @delimiter || last_entry.count(@delimiter) != 2
			raise "Clocked in, but wrong format"
		end

		clocked_in_timestamp = DateTime.parse(last_entry).to_time.to_i
		clocked_out_timestamp = self.now_rounded()
		if clocked_in_timestamp == clocked_out_timestamp
			clocked_out_timestamp += @rounding_amount
		end

		rest_of_entry = "#{ToS.time(clocked_out_timestamp)}#{@delimiter}#{comment}\n"
		File.open(@timesheet_filename, 'a') { |f| f.write(rest_of_entry) }

		return last_entry.chomp+rest_of_entry
	end

	def clocked_in?(last_entry_override = nil)
		(last_entry_override ? last_entry_override : self.last_entry)[-1] != "\n"
	end

	protected
	def last_entry()
		File.open(@timesheet_filename) do |f; i, start_of_file, lines|
			i = 0
			start_of_file = -f.size
			begin
				if (i-=SEEK_STEP) > start_of_file
					f.seek(i, IO::SEEK_END)
				else
					f.seek(0, IO::SEEK_SET)
				end

				lines = f.readlines
			end while lines.length <= 1 && i > start_of_file
			return lines.length == 0 ? "\n" : lines[-1]
		end
	end

	def now_rounded()
		now = Time.now.to_i
		now += Time.now.utc_offset # now as if it was utc

		seconds_past_now_floored = now % @rounding_amount
		now_floored = now - seconds_past_now_floored

		return seconds_past_now_floored > @rounding_amount/2 ? now_floored+@rounding_amount : now_floored
	end

end
