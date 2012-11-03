#!/usr/bin/env ruby
require_relative 'timesheet_clock'

if ARGV.length != 1
	$stderr.puts("Usage: #{$0} TIMESHEET_FILE")
	exit(1)
end

puts(TimesheetClock.new(ARGV[0]).clock_in())
