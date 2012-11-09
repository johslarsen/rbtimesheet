#!/usr/bin/env ruby
require 'minitest/autorun'
require_relative '../lib/timesheet/entry'

class TestEntry < MiniTest::Unit::TestCase
	def setup
		@midnight = Time.utc(2012, 03, 14)
		@midday =   Time.utc(2012, 03, 14, 12)
		@midday_utime = @midday.to_i
	end

	def test_creation_and_attributes
		to = @midday_utime+1

		refute_nil( (entry=Timesheet::Entry.new(@midday, to, "a comment")) )

		assert_equal(@midday_utime, entry.from)
		assert_equal(to, entry.to)
		assert_equal(to-@midday_utime, entry.duration)
		assert_equal(@midnight.to_i, entry.midnight)
	end

	def test_comparable
		first = Timesheet::Entry.new(@midnight,   @midday, "a comment")
		last =  Timesheet::Entry.new(@midnight+1, @midday, "a comment")

		assert_equal(0,  first <=> first)
		assert_equal(-1, first <=> last)
		assert_equal(1,  last  <=> first)
		assert_equal(0,  last  <=> last)

		assert(first == first)
		assert(first <= first)
		assert(first >= first)
		refute(first < first)
		refute(first > first)

		assert(first != last)
		refute(first == last)
		assert(last  >= first)
		assert(last  >  first)
		assert(first <  last)
		assert(first <= last)
	end

	def test_incorrect_arguments
		assert_raises(ArgumentError) {Timesheet::Entry.new(@midday, @midday_utime,                             "something")}
		assert_raises(ArgumentError) {Timesheet::Entry.new(@midday, @midday_utime-1,                           "something")}
		assert_raises(ArgumentError) {Timesheet::Entry.new(@midday, @midday_utime+Timesheet::SECONDS_IN_A_DAY, "something")}
		assert_raises(ArgumentError) {Timesheet::Entry.new(@midday, @midday_utime+1,                           nil)}
	end

	def test_boundary
		refute_nil(Timesheet::Entry.new(@midnight, @midnight+Timesheet::SECONDS_IN_A_DAY-1, "something"))
		assert_raises(ArgumentError) {Timesheet::Entry.new(@midnight, @midnight+Timesheet::SECONDS_IN_A_DAY, "something")}
	end
end
