#!/usr/bin/env ruby
require_relative 'common'

module Timesheet
	class Entry

		include Comparable

		attr_reader :from
		attr_reader :to
		attr_reader :comment

		def initialize(from, to, comment)
			@from = from.to_i
			@to = to.to_i
			@comment = comment.to_s

			raise ArgumentError, "from must be before to"  unless @from < @to
			raise ArgumentError, "from and to must be on the same day"  unless @to <= midnight+SECONDS_IN_A_DAY
			raise ArgumentError, "Require non-empty comment"  unless !@comment.empty?
		end

		def to_s
			[Timesheet.to_s_date(@from), Timesheet.to_s_time(@from), Timesheet.to_s_time(@to), Timesheet.to_s_duration(duration), @comment].join(" ")
		end

		def midnight
			@from - (@from%SECONDS_IN_A_DAY)
		end

		def duration(limit_from=nil, limit_to=nil)
			duration = [@to, limit_to].compact.min - [@from, limit_from].compact.max
			duration>0 ? duration : 0
		end

		def <=>(other)
			@from <=> other.from
		end
	end
end
