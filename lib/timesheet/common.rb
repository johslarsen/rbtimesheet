#!/usr/bin/env ruby

module Timesheet
	SECONDS_IN_A_MINUTE = 60
	MINUTES_IN_AN_HOUR  = 60
	HOURS_IN_A_DAY      = 24
	DAYS_IN_A_WEEK      = 7
	WEEKS_IN_A_YEAR     = 53

	SECONDS_IN_AN_HOUR = SECONDS_IN_A_MINUTE * MINUTES_IN_AN_HOUR
	SECONDS_IN_A_DAY = SECONDS_IN_AN_HOUR * HOURS_IN_A_DAY
	SECONDS_IN_A_WEEK = SECONDS_IN_A_DAY * DAYS_IN_A_WEEK

	RATE_KEY = "rate"
	RATE_CURRENCY_KEY = "rate_currency"

	def self.to_s_date(utime)
		Time.at(utime).utc.strftime("%Y-%m-%d")
	end

	def self.to_s_time(utime)
		Time.at(utime).utc.strftime("%H:%M")
	end

	def self.to_s_duration(seconds)
		"%5d:%02d" % (seconds/SECONDS_IN_A_MINUTE).divmod(MINUTES_IN_AN_HOUR)
	end

	def self.to_s_value(n)
		"%.2f" % n
	end

	def self.midnight(utime)
		utime-(utime%SECONDS_IN_A_DAY)
	end
end
