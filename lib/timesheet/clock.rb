#!/usr/bin/env ruby
require 'date'
require_relative 'common'

module Timesheet
	class Clock

		SEEK_STEP = 256

		def initialize(timesheet_filename, delimiter="\t", rounding_amount=15*Timesheet::SECONDS_IN_A_MINUTE)
			@timesheet_filename = timesheet_filename
			@delimiter = delimiter
			@rounding_amount = rounding_amount
		end

		def clock_in
			raise "Already clocked in"  if clocked_in?

			from = now_rounded
			start_of_entry = "#{Timesheet.to_s_date(from)}#{@delimiter}#{Timesheet.to_s_time(from)}#{@delimiter}"
			File.open(@timesheet_filename, 'a') { |f| f.write(start_of_entry) }

			start_of_entry
		end

		def clock_out(comment)
			last_entry = self.last_entry
			raise "Not clocked in"  unless clocked_in?(last_entry)
			raise "Clocked in, but wrong format"  if last_entry[-@delimiter.length..-1] != @delimiter || last_entry.scan(@delimiter).size != 2

			clocked_in_timestamp = DateTime.parse(last_entry).to_time.to_i
			clocked_out_timestamp = now_rounded
			clocked_out_midnight = Timesheet.midnight(clocked_out_timestamp)

			clocked_out_after_midnight = clocked_out_timestamp - clocked_out_midnight
			clocked_out_after_midnight += clocked_in_timestamp-clocked_out_timestamp + @rounding_amount  if clocked_in_timestamp >= clocked_out_timestamp

			if clocked_out_midnight > clocked_in_timestamp
				clocked_out_after_midnight += clocked_out_midnight-Timesheet.midnight(clocked_in_timestamp)
			end

			clocked_out_relative_timestring = "%02d:%02d" % (clocked_out_after_midnight/Timesheet::SECONDS_IN_A_MINUTE).divmod(Timesheet::MINUTES_IN_AN_HOUR)
			rest_of_entry = "#{clocked_out_relative_timestring}#{@delimiter}#{comment}\n"
			File.open(@timesheet_filename, 'a') { |f| f.write(rest_of_entry) }

			last_entry.chomp+rest_of_entry
		end

		def clocked_in?(last_entry_override = nil)
			(last_entry_override ? last_entry_override : self.last_entry)[-1] != "\n"
		end

		protected
		def last_entry
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

		def now_rounded
			now = Time.now.to_i
			now += Time.now.utc_offset # now as if it was UTC

			seconds_past_now_floored = now % @rounding_amount
			now_floored = now - seconds_past_now_floored

			seconds_past_now_floored > @rounding_amount/2 ? now_floored+@rounding_amount : now_floored
		end
	end
end
