#!/usr/bin/env ruby
require_relative 'timesheet_ascii_tables'
require_relative 'timesheet_csv_string'

if 1 > ARGV.length || ARGV.length > 2
	$stderr.puts("USAGE: #{$0} TIMESHEET_FILE [DELIMITER]")
	exit(1)
end


if ARGV[0] == "-"
	csv = $stdin.read
else
	csv = File.open(ARGV[0]) { |f|
		f.read()
	}
end

ts = TimesheetCSVString.new(csv, ARGV.length == 2 ? ARGV[1] : "\t")
ts_table = TimesheetASCIITables.new(ts)

puts "##### Report for the timesheet \"#{ARGV[0]}\" #####"
puts
puts "Metadata"
puts "--------"
puts ts_table.metadata()
puts
if ts.rate?
	puts "      From             To  Duration * Rate = Value"
	puts "----------     ----------  -----------------------"
else
	puts "      From             To  Duration"
	puts "----------     ----------  --------"
end
puts ts_table.summary()
puts
puts "      Date Start   End Duration Comment"
puts "---------- ----- ----- -------- -------"
puts ts_table.entries()
puts
puts "  Weekday Duration"
puts "--------- --------"
puts ts_table.sum_by_weekday(false)
puts
puts " Hour Duration"
puts "----- --------"
puts ts_table.sum_by_hour(false)
puts
puts "W# Duration"
puts "-- --------"
puts ts_table.sum_by_week()
puts
puts "      Date Duration"
puts "---------- --------"
puts ts_table.sum_by_date()
