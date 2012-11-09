#!/usr/bin/env ruby
require 'date'
require 'json'
require_relative 'document'
require_relative 'entry'

module Timesheet
	class Parser

		FIELD_DATE      = 0
		FIELD_TIME_FROM = 1
		FIELD_TIME_TO   = 2
		FIELD_COMMENT   = 3..-1

		COMMENT_CHAR = "#"
		TIME_DELIMITER = ":"

		def self.csv(csv, delimiter = "\t")
			metadata = {}
			entries = []

			csv.split("\n").each do |row|
				next if row.empty?

				if row[0] == COMMENT_CHAR
					metadata.merge!(self.csv_comment(row[1..-1]))
				else
					entries += self.csv_entry(row, delimiter)
				end
			end

			Timesheet::Document.new(metadata, entries)
		end

		private

		def self.parse_date(date)
			DateTime.parse(date).to_time.to_i
		end

		def self.parse_time(time)
			fields = time.split(TIME_DELIMITER)

			raise "Cannot parse '#{time}' as a time of day" if 1 > fields.length || fields.length > 3

			seconds = 0
			seconds += fields.pop.to_f                                  if fields.length == 3
			seconds += fields.pop.to_f * Timesheet::SECONDS_IN_A_MINUTE if fields.length == 2

			seconds + fields.pop.to_f * Timesheet::SECONDS_IN_AN_HOUR
		end

		def self.split_into_single_day_entries(midnight, from_after_midnight, to_after_midnight, comment)
			entries = []

			from = midnight+from_after_midnight
			while to_after_midnight > 0 do
				to = midnight + (to_after_midnight < Timesheet::SECONDS_IN_A_DAY ? to_after_midnight : Timesheet::SECONDS_IN_A_DAY)
				entries.push(Timesheet::Entry.new(from, to, comment))

				from = midnight = to
				to_after_midnight -= Timesheet::SECONDS_IN_A_DAY
			end

			entries
		end

		def self.csv_comment(comment)
			key, delimiter, value = comment.partition("=")

			return delimiter.empty? ? {} : {key.strip => JSON.parse("["+value.strip+"]")[0]}
		end

		def self.csv_entry(entry, delimiter)
			fields = entry.split(delimiter)

			midnight = self.parse_date(fields[FIELD_DATE])
			from_after_midnight = self.parse_time(fields[FIELD_TIME_FROM])
			to_after_midnight = self.parse_time(fields[FIELD_TIME_TO])
			comment = fields[FIELD_COMMENT].join(delimiter)

			self.split_into_single_day_entries(midnight, from_after_midnight, to_after_midnight, comment)
		end
	end
end
