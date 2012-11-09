require 'date'
require 'json'
require_relative 'document'
require_relative 'entry'

module Timesheet
	class Parser

		DEFAULT_FIELD_MAP = {
			date_from: 0,
			date_to:   0, # intentionally the same field
			time_from: 1,
			time_to:   2,
			comment:   3..-1,
		}.freeze

		COMMENT_CHAR = "#"
		TIME_DELIMITER = ":"

		def initialize(override_field_map = {})
			@field_map = DEFAULT_FIELD_MAP.merge(override_field_map).freeze
		end

		def csv(csv, delimiter = "\t")
			@delimiter = delimiter

			metadata = {}
			entries = []

			csv.split("\n").each do |row|
				next if row.empty?

				if row[0] == COMMENT_CHAR
					metadata.merge!(csv_comment(row.sub(/^#{COMMENT_CHAR}*/, "")))
				else
					entries += csv_entry(row)
				end
			end

			Timesheet::Document.new(metadata, entries)
		end

		private

		def parse_date(date)
			DateTime.parse(date).to_time.to_i
		end

		def parse_time(time)
			fields = time.split(TIME_DELIMITER)

			raise "Cannot parse '#{time}' as a time of day" if 1 > fields.length || fields.length > 3

			seconds = 0
			seconds += fields.pop.to_f                                  if fields.length == 3
			seconds += fields.pop.to_f * Timesheet::SECONDS_IN_A_MINUTE if fields.length == 2

			seconds + fields.pop.to_f * Timesheet::SECONDS_IN_AN_HOUR
		end

		def split_into_single_day_entries(midnight, from_after_midnight, to_after_midnight, comment)
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

		def extract_field(fields, k)
			field = fields[@field_map[k]]

			field.respond_to?(:each) ? field.to_a.join(@delimiter) : field
		end

		def entries_from_fields(fields)
			midnight = parse_date(extract_field(fields, :date_from))
			to_midnight = parse_date(extract_field(fields, :date_to))
			from_after_midnight = parse_time(extract_field(fields, :time_from))
			to_after_midnight = (to_midnight-midnight) + parse_time(extract_field(fields, :time_to))
			comment = extract_field(fields, :comment)

			split_into_single_day_entries(midnight, from_after_midnight, to_after_midnight, comment)
		end

		def csv_comment(comment)
			key, delimiter, value = comment.partition("=")

			delimiter.empty? ? {} : {key.strip => JSON.parse("["+value.strip+"]")[0]}
		end

		def csv_entry(entry)
			entries_from_fields(entry.split(@delimiter))
		end
	end
end
