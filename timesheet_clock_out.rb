#!/usr/bin/env ruby
require_relative 'timesheet_clock'

if ARGV.length != 2
	$stderr.puts("USAGE: #{$0} TIMESHEET_FILE COMMENT")
	exit(1)
end

puts(TimesheetClock.new(ARGV[0]).clock_out(ARGV[1]))
