#!/usr/bin/env ruby
require 'minitest/autorun'
require_relative '../lib/timesheet/document'
require_relative '../lib/timesheet/entry'


class TestDocument < MiniTest::Unit::TestCase

	ENTRY_DURATION = Timesheet::SECONDS_IN_AN_HOUR-1

	def setup
		first_from = Time.utc(2012,01,01,12).to_i
		@first = Timesheet::Entry.new(first_from, first_from+ENTRY_DURATION, "first")
		overlapping_from = first_from+1
		@overlappig = Timesheet::Entry.new(overlapping_from, overlapping_from+ENTRY_DURATION, "overlapping")
		last_from = Time.utc(2012,01,02,12).to_i
		@last = Timesheet::Entry.new(last_from, last_from+ENTRY_DURATION, "last")

		@entries = [@overlappig, @last, @first] # intentionally out of order
		@metadata = {Timesheet::RATE_KEY => 199, Timesheet::RATE_CURRENCY_KEY => "NOK", "something" => 42}
	end

	def test_creation_attributes_and_compareable
		refute_nil( (a=Timesheet::Document.new(@metadata, @entries)) )

		assert_equal(@first.from, a.from)
		assert_equal(@last.to, a.to)
		assert_equal(@entries.length*ENTRY_DURATION, a.duration)

		assert(a.rate?)
		assert(a.rate_currency?)
		assert_equal(@metadata[Timesheet::RATE_KEY], a.rate)
		assert_equal(@metadata[Timesheet::RATE_CURRENCY_KEY], a.rate_currency)
		assert_equal(ENTRY_DURATION.to_f*@entries.length/Timesheet::SECONDS_IN_AN_HOUR*a.rate, a.value)
		assert_equal(@metadata, a.metadata)

		assert_equal(@entries.sort, a.entries)
		assert_equal(@first, @entries.pop)
		refute_equal(@entries.sort, a.entries)

		@metadata.delete(Timesheet::RATE_KEY)
		@metadata.delete(Timesheet::RATE_CURRENCY_KEY)
		refute_equal(@metadata, a.metadata)

		refute_nil( (b=Timesheet::Document.new(@metadata, @entries)) )

		assert_equal(@entries.sort, b.entries)
		assert_equal(@metadata, b.metadata)
		refute(b.rate?)
		refute(b.rate_currency?)
		assert_equal(nil, b.rate)
		assert_equal(nil, b.rate_currency)
		assert_equal(nil, b.value)

		assert_equal(0,  a <=> a)
		assert_equal(-1, a <=> b)
		assert_equal(1,  b <=> a)
		assert_equal(0,  b <=> b)

		assert(a == a)
		assert(a <= a)
		assert(a >= a)
		refute(a <  a)
		refute(a >  a)

		refute(a == b)
		assert(a != b)
		assert(a <= b)
		assert(a <  b)
		assert(b >= a)
		assert(b >  a)
		refute(a >= b)
		refute(a >  b)
		refute(b <= a)
		refute(b <  a)
	end

	def test_enumerable
		refute_nil( (ts=Timesheet::Document.new(@metadata, @entries)) )

		ni = 0
		@entries.each_with_index do |entry, i|
			ni+=1
			assert(@entries.include?(entry))
		end
		assert_equal(@entries.length, ni)
	end

	def test_sums
		refute_nil( (ts=Timesheet::Document.new(@metadata, @entries)) )

		sum_by_hour = ts.sum_by_hour
		assert_equal(Timesheet::HOURS_IN_A_DAY, sum_by_hour.length)
		expected = [0]*Timesheet::HOURS_IN_A_DAY
		expected[12] += @entries.length*ENTRY_DURATION
		assert_equal(expected, sum_by_hour)

		sum_by_date = ts.sum_by_date
		assert_equal(2, sum_by_date.length)
		assert_equal(2*ENTRY_DURATION, sum_by_date[Timesheet::to_s_date(@first.from)])
		assert_equal(1*ENTRY_DURATION, sum_by_date[Timesheet::to_s_date(@last.from)])

		sum_by_weekday = ts.sum_by_weekday
		assert_equal(Timesheet::DAYS_IN_A_WEEK, sum_by_weekday.length)
		expected = [0]*Timesheet::DAYS_IN_A_WEEK
		expected[Time.at(@first.from).wday] += 2*ENTRY_DURATION
		expected[Time.at(@last.from).wday] += ENTRY_DURATION
		assert_equal(expected, sum_by_weekday)

		sum_by_week = ts.sum_by_week
		assert_equal(Timesheet::WEEKS_IN_A_YEAR, sum_by_week.length)
		expected = [0]*Timesheet::WEEKS_IN_A_YEAR
		expected[Time.at(@first.from).strftime("%W").to_i] += 2*ENTRY_DURATION
		expected[Time.at(@last.from).strftime("%W").to_i] += ENTRY_DURATION
		assert_equal(expected, sum_by_week)
	end

	def test_incorrect_arguments
		refute_nil(Timesheet::Document.new({}, @entries))

		assert_raises(TypeError) { Timesheet::Document.new(nil, @entries) }
		assert_raises(NoMethodError) { Timesheet::Document.new({}, nil) }
		assert_raises(ArgumentError) { Timesheet::Document.new({}, []) }
	end
end
