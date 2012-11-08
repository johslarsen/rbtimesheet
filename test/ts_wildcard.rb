#!/usr/bin/env ruby
Dir.glob(File.expand_path("../tc_*.rb", __FILE__)).each do |filename|
	require filename
end
