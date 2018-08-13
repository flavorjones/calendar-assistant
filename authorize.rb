#! /usr/bin/env ruby

#
#  code taken from https://github.com/northworld/google_calendar/blob/master/readme_code.rb
#

def usage
  puts "USAGE: authorize <calendar-id>"
  exit 1
end

require_relative 'calendar-assistant'

usage unless ARGV[0]
CALENDAR_ID = ARGV[0]

puts "NOTE: creating calendar ..."
cal = CalendarAssistant.calendar_for CALENDAR_ID
        
if ! cal.refresh_token

  puts "Visit the following web page in your browser and approve access."
  puts cal.authorize_url
  puts "\nCopy the code that Google returned and paste it here:"

  refresh_token = cal.login_with_auth_code( $stdin.gets.chomp )
  CalendarAssistant.save_token_for CALENDAR_ID, refresh_token
end

puts "NOTE: retrieving calendar ..."
cal.retrieve_calendar

if cal.summary
  puts "Successfully authenticated and authorized for #{cal.summary}"
else
  puts "ERROR: did not authenticate"
end
