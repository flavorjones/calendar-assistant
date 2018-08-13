#! /usr/bin/env ruby

#
#  code taken from https://github.com/northworld/google_calendar/blob/master/readme_code.rb
#

def usage
  puts "USAGE: authorize <calendar-id>"
  exit 1
end

require 'google_calendar'
require 'json'
require 'yaml'

CLIENT_ID_FILE = "client_id.json"
CALENDAR_TOKENS_FILE = "calendar_tokens.yml"

usage unless ARGV[0]
CALENDAR_ID = ARGV[0]

CLIENT_ID = JSON.parse(File.read(CLIENT_ID_FILE))

cal = Google::Calendar.new(:client_id     => CLIENT_ID["installed"]["client_id"],
                           :client_secret => CLIENT_ID["installed"]["client_secret"],
                           :calendar      => CALENDAR_ID,
                           :redirect_url  => "urn:ietf:wg:oauth:2.0:oob")

calendar_tokens = File.exists?(CALENDAR_TOKENS_FILE) ?
                    YAML.load(File.read(CALENDAR_TOKENS_FILE)) :
                    Hash.new

refresh_token = calendar_tokens[CALENDAR_ID]

if refresh_token

  puts "NOTE: logging in ..."
  cal.login_with_refresh_token(refresh_token)

else

  puts "Visit the following web page in your browser and approve access."
  puts cal.authorize_url
  puts "\nCopy the code that Google returned and paste it here:"

  refresh_token = cal.login_with_auth_code( $stdin.gets.chomp )

  calendar_tokens[CALENDAR_ID] = refresh_token
  File.open(CALENDAR_TOKENS_FILE, "w") { |f| f.write calendar_tokens.to_yaml }

end

puts "NOTE: retrieving calendar ..."
cal.retrieve_calendar

if cal.summary
  puts "Successfully authenticated and authorized for #{cal.summary}"
else
  puts "ERROR: did not authenticate"
end
