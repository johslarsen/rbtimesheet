#!/usr/bin/env ruby
require 'minitest/autorun'
require 'tempfile'
require_relative '../lib/timesheet/clock'
require_relative '../lib/timesheet/parser'

class TestClock < MiniTest::Unit::TestCase
	def setup
		@f = Tempfile.new("timesheet")
	end

	def teardown
		@f.close
		@f.unlink
	end

	def test_normal_usage
		refute_nil(clock = Timesheet::Clock.new(@f.path))
		add_and_check_two_entries(clock)

	end

	def test_alternate_delimter_and_rounding_amount
		delimiter = ";"
		rounding_amount = Timesheet::SECONDS_IN_AN_HOUR

		refute_nil(clock = Timesheet::Clock.new(@f.path, delimiter, rounding_amount))
		add_and_check_two_entries(clock)

		refute_nil(ts = Timesheet::Parser.new.csv(@f.read, delimiter))
		assert_equal(2*rounding_amount, ts.duration)
	end

	def test_clock_out_failing_with_corrupt_entries
		refute_nil(clock = Timesheet::Clock.new(@f.path))
		add_and_check_two_entries(clock)
		@f.seek(0, File::SEEK_END)

		@f.write("some random text\t including enough\t delimiters, but not at the end")
		@f.flush
		assert(clock.clocked_in?)
		assert_raises(RuntimeError) { clock.clock_out("a comment") }
		@f.write("\n")
		@f.flush
		refute(clock.clocked_in?)

		@f.write("too few delimiters, but ending wuth one\t")
		@f.flush
		assert(clock.clocked_in?)
		assert_raises(RuntimeError) { clock.clock_out("a comment") }
		@f.write("\n")
		@f.flush
		refute(clock.clocked_in?)

		@f.write("too\t many\t delimiters\t, and\t ending\t in\t one\t")
		@f.flush
		assert_raises(RuntimeError) { clock.clock_out("a comment") }
	end

	def test_clock_in_working_even_if_earlier_entries_are_corrupt
		refute_nil(clock = Timesheet::Clock.new(@f.path))
		add_and_check_two_entries(clock)
		@f.seek(0, File::SEEK_END)

		@f.write("a corrupt entry")
		@f.flush
		assert(clock.clocked_in?)
		assert_raises(RuntimeError) { clock.clock_in }

		@f.write("\n")
		@f.flush
		refute(clock.clocked_in?)
		refute(clock.clock_in.empty?)
	end

	def add_and_check_two_entries(clock)
		refute(clock.clocked_in?)
		assert_raises(RuntimeError) { clock.clock_out("a comment") }

		refute(clock.clock_in.empty?)
		assert(clock.clocked_in?)
		assert_raises(RuntimeError) { clock.clock_in }

		refute(clock.clock_out("a comment").empty?)
		refute(clock.clocked_in?)
		assert_raises(RuntimeError) { clock.clock_out("a comment") }

		refute(clock.clock_in.empty?)
		assert(clock.clocked_in?)
		assert_raises(RuntimeError) { clock.clock_in }

		refute(clock.clock_out("a comment").empty?)
		refute(clock.clocked_in?)
		assert_raises(RuntimeError) { clock.clock_out("a comment") }

	end
end
