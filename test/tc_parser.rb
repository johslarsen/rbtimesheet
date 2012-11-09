#!/usr/bin/env ruby
require 'minitest/autorun'
require 'json'
require_relative '../lib/timesheet/parser'

class TestParser < MiniTest::Unit::TestCase
	def setup
		@some_metadata = {Timesheet::RATE_KEY => 200, Timesheet::RATE_CURRENCY_KEY => "NOK"}
		@parser = Timesheet::Parser.new
	end

	def test_single_day_entry
		from = Time.utc(2012, 3, 14, 1).to_i
		to = from + Timesheet::SECONDS_IN_AN_HOUR

		refute_nil(ts=@parser.csv(csv_string([csv_entry(from, to)])))
		assert_equal(1, ts.entries.length)
		assert_equal(from, ts.entries[0].from)
		assert_equal(to, ts.entries[0].to)
	end

	def test_multi_day_entry
		from = Time.utc(2012, 3, 14, 23).to_i
		start_of_next_day = Time.utc(2012, 3, 15, 0, 0).to_i
		to = start_of_next_day+1*Timesheet::SECONDS_IN_AN_HOUR

		refute_nil(ts=@parser.csv(csv_string([csv_entry(from, to)])))
		assert_equal(2, ts.entries.length)
		assert_equal(from,              ts.entries[0].from)
		assert_equal(start_of_next_day, ts.entries[0].to)
		assert_equal(start_of_next_day, ts.entries[1].from)
		assert_equal(to,                ts.entries[1].to)
	end

	def test_multiple_entries_are_sorted
		from = [ # intentionally unsorted
			Time.utc(1970, 1, 1, 0).to_i,
			Time.utc(2012, 12, 21, 0).to_i,
			Time.utc(2012, 6, 28, 3, 18).to_i,
			Time.utc(2012, 3, 14, 15, 9).to_i,
		]
		to = from.map {|u| u+2*Timesheet::SECONDS_IN_AN_HOUR}
		entries = from.zip(to).map {|ft| csv_entry(ft[0], ft[1])}

		from.sort!
		to.sort!

		refute_nil(ts=@parser.csv(csv_string(entries)))
		assert_equal(from.length, ts.entries.length)
		ts.entries.each_with_index do |e, i|
			assert_equal(from[i], e.from)
			assert_equal(to[i], e.to)
		end
	end

	def test_multiple_single_and_multi_day_entries
		sfrom = [
			Time.utc(1991, 8, 25, 0).to_i,
			Time.utc(1991, 10, 5, 0).to_i,
		]
		sto = sfrom.map {|u| u+2*Timesheet::SECONDS_IN_AN_HOUR}
		entries = sfrom.zip(sto).map {|ft| csv_entry(ft[0], ft[1])}

		mfrom = [
			Time.utc(2012, 2, 17, 23).to_i,
			Time.utc(2012, 12, 24, 23).to_i,
		]
		mto = mfrom.map {|u| u+2*Timesheet::SECONDS_IN_AN_HOUR}
		entries += mfrom.zip(mto).map {|ft| csv_entry(ft[0], ft[1])}

		refute_nil(ts=@parser.csv(csv_string(entries)))
		assert_equal(sfrom.length+mfrom.length*2, ts.entries.length)
		ts.each_with_index do |e, i; mi, start_of_next_day|
			if i < sfrom.length
				assert_equal(sfrom[i], e.from)
				assert_equal(sto[i], e.to)
			else
				mi = (i-sfrom.length) / 2
				start_of_next_day = mfrom[mi]+Timesheet::SECONDS_IN_AN_HOUR
				if e.to == start_of_next_day
					assert_equal(mfrom[mi], e.from)
					assert_equal(start_of_next_day, e.to)
				else
					assert_equal(start_of_next_day, e.from)
					assert_equal(mto[mi], e.to)
				end
			end
		end
	end

	def test_ignoring_newlines_and_missing_metadata
		from = [
			Time.utc(1992, 1, 31).to_i,
			Time.utc(1992, 10, 16).to_i,
		]
		to = from.map {|u| u + Timesheet::SECONDS_IN_AN_HOUR}

		csv  = "\n\n"
		csv += csv_entry(from[0], to[0])
		csv += "\n\n\n\n"
		csv += csv_entry(from[1], to[1])
		csv += "\n\n"

		refute_nil(ts = @parser.csv(csv))
		assert_equal(from.length, ts.entries.length)
		ts.entries.each_with_index do |e, i|
			assert_equal(from[i], e.from)
			assert_equal(to[i], e.to)
		end
	end

	def test_overriding_field_map
		parser = Timesheet::Parser.new({
			comment: 0,
			time_from: 1,
			time_to: 2,
			date_from: 3,
			date_to: 4,
		})
		refute_nil(parser)

		comment="lorem ipsum"
		from = [
			Time.utc(2000, 1, 1).to_i,
			Time.utc(2001, 9, 11, 23).to_i,
		]
		to = from.map {|u| u + 2*Timesheet::SECONDS_IN_AN_HOUR}

		entries = from.zip(to).map do |ft|
			[comment, Timesheet.to_s_time(ft[0]), Timesheet.to_s_time(ft[1]), Timesheet.to_s_date(ft[0]), Timesheet.to_s_date(ft[1])].join("\t")
		end

		refute_nil(ts = parser.csv(csv_string(entries)))
		assert_equal(1+1*2, ts.entries.length)

		assert_equal(from[0], ts.entries[0].from)
		assert_equal(to[0], ts.entries[0].to)

		start_of_next_day = from[1] + Timesheet::SECONDS_IN_AN_HOUR
		assert_equal(from[1], ts.entries[1].from)
		assert_equal(start_of_next_day, ts.entries[1].to)
		assert_equal(start_of_next_day, ts.entries[2].from)
		assert_equal(to[1], ts.entries[2].to)
	end

	def test_alternate_delimiter
		delimiter = ";"

		from = Time.utc(1991, 11, 2).to_i
		to = from+Timesheet::SECONDS_IN_AN_HOUR
		entry = csv_entry(from, to).gsub(/\t/, delimiter)

		refute_nil(ts = @parser.csv(csv_string([entry]), delimiter))
		assert_equal(1, ts.entries.length)
		assert_equal(from, ts.entries[0].from)
		assert_equal(to, ts.entries[0].to)
	end

	def test_float_time_parsing
		from = Time.utc(2012, 6, 28, 3, 18, 53).to_i
		to = from+Timesheet::SECONDS_IN_AN_HOUR

		from_str = "3.3:0:53"
		to_str = "04:18:53"
		entry = [Timesheet.to_s_date(from), from_str, to_str, "a comment"].join("\t")

		refute_nil(ts = @parser.csv(csv_string([entry])))
		assert_equal(1, ts.entries.length)
		assert_equal(from, ts.entries[0].from)
		assert_equal(to, ts.entries[0].to)
	end

	def test_incorrect_arguments
		assert_raises(ArgumentError) { @parser.csv(csv_string([], true)) }
		assert_raises(ArgumentError) { @parser.csv(csv_string([], false)) }
	end

	def metadata_csv(h)
		h.map do |k, v|
			"##{k} = #{JSON.generate([v])[1..-2]}"
		end.join("\n")
	end

	def date_and_from_to_time(from, to = from)
		[Timesheet.to_s_date(from), Timesheet.to_s_time(from), Timesheet.to_s_time(to)]
	end

	def csv_entry(from, to, comment = "a comment")
		midnight = from - (from%Timesheet::SECONDS_IN_A_DAY)
		to_str = Timesheet.to_s_duration(to-midnight)

		[Timesheet.to_s_date(from), Timesheet.to_s_time(from), to_str, comment].join("\t")
	end

	def csv_string(entries, include_some_metadata = true)
		lines = include_some_metadata ? [metadata_csv(@some_metadata)] : []
		lines += entries

		lines.join("\n")
	end
end
