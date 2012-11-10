#!/usr/bin/env ruby
require_relative 'common'

module Timesheet
	class Document

		include Comparable
		include Enumerable

		attr_reader :entries
		attr_reader :metadata

		def initialize(metadata, entries)
			@metadata = metadata.clone
			@entries = entries.sort

			raise ArgumentError, "entries must be non-empty" unless !entries.empty?
		end

		def rate
			@metadata[RATE_KEY]
		end

		def rate?
			@metadata.has_key?(RATE_KEY)
		end

		def rate_currency
			@metadata[RATE_CURRENCY_KEY]
		end

		def rate_currency?
			@metadata.has_key?(RATE_CURRENCY_KEY)
		end

		def duration
			@entries.inject(0) { |memo, obj| memo + obj.duration }
		end

		def from
			@entries[0].from
		end

		def to
			@entries[-1].to
		end

		def value
			self.rate? ? self.duration*(self.rate.to_f/SECONDS_IN_AN_HOUR) : nil
		end

		def <=>(other)
			self.from <=> other.from
		end

		def each
			@entries.each do |i|
				yield i
			end
		end

		def to_s
			self.summary
		end

		def summary
			currency = ""
			rate_unit = ""
			if self.rate_currency?
				currency = "[#{self.rate_currency}]"
				rate_unit = "[#{currency[1..-2]}/Hour]"
			end

			rate_and_value = "* %d%s = %s%s" % [self.rate, rate_unit, Timesheet.to_s_value(self.value), currency]

			[Timesheet.to_s_date(self.from), "---", Timesheet.to_s_date(self.to), Timesheet.to_s_duration(self.duration), rate_and_value].join(" ")
		end

		def sum_by_hour
			([nil]*HOURS_IN_A_DAY).each_with_index.map do |n, i|
				@entries.inject(0) do |sum, obj; midnight|
					midnight = obj.midnight
					sum += obj.duration(midnight + i*SECONDS_IN_AN_HOUR, midnight + (i+1)*SECONDS_IN_AN_HOUR)
				end
			end
		end

		def sum_by_date
			@entries.each.with_object(Hash.new(0)) do |entry, dates|
				dates[Timesheet.to_s_date(entry.from)] += entry.duration
			end
		end

		def sum_by_weekday
			@entries.each.with_object([0]*DAYS_IN_A_WEEK) do |entry, weekdays|
				weekdays[Time.at(entry.from).wday] += entry.duration
			end
		end

		def sum_by_week
			@entries.each.with_object([0]*WEEKS_IN_A_YEAR) do|entry, weeks|
				weeks[Time.at(entry.from).strftime("%W").to_i] += entry.duration
			end
		end
	end
end
