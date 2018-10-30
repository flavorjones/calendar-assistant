
# calendar assistant

A command-line tool to help me manage my Google Calendar.

- book (and re-book) one-on-ones and other meetings automatically
- set up all-day events to let people know your location in the world
- easily join the videoconference for your current meeting

[![Concourse CI](https://ci.nokogiri.org/api/v1/teams/calendar-assistants/pipelines/calendar-assistant/jobs/rake-spec/badge)](https://ci.nokogiri.org/teams/calendar-assistants/pipelines/calendar-assistant)
[![Maintainability](https://api.codeclimate.com/v1/badges/3525792e1feeccfd8875/maintainability)](https://codeclimate.com/github/flavorjones/calendar-assistant/maintainability)

## Usage

Head to [the quickstart](https://developers.google.com/calendar/quickstart/ruby) to enable the Calendar API for your Google account and create a new "project". Save the project info in `credentials.json`.

Then run `calendar-assistant authorize PROFILE_NAME` (see below for details).

Once you're authorized, feel free to delete the `credentials.json` file. You can re-download that info again if you ever need it.


## Features

### Pretty Display

Events are nicely formatted, with faint strikeouts for events you've declined, and some additional attributes listed when present (e.g., "needsAction", "self", "not-busy", "1:1" ...)


### Date and Time Specification

All dates and times are interpreted by [Chronic](https://github.com/mojombo/chronic) and so can be fuzzy terms like "tomorrow", "tuesday", "next thursday", and "two days from now" as well as specific dates and times.

For a date range or a datetime range, split the start and end with `..` or `...` (with or without spaces) like:

* "tomorrow ... three days from now"
* "2018-09-24..2018-09-27".

Also note that every command will adopt an intelligent default, which is generally "today" or "now".


### Duration Specification

Some duration-related preferences are interpreted by [ChronicDuration](https://github.com/henrypoydar/chronic_duration) and so can be terms like "10m", "30 minutes", "four hours", etc.


### Preferences

All tokens and preferences will be stored in `~/.calendar-assistant` which is in TOML format.


## Commands

<pre>
<b>$</b> calendar-assistant help
Commands:
  calendar-assistant authorize PROFILE_NAME                       # create (or validate) a profile named NAME with calendar access
  calendar-assistant availability [DATE | DATERANGE | TIMERANGE]  # Show your availability for a date or range of dates (default 'today')
  calendar-assistant config                                       # Dump your configuration parameters (merge of defaults and overrides from /home/flavorjones/.calendar-assistant)
  calendar-assistant help [COMMAND]                               # Describe available commands or one specific command
  calendar-assistant join [TIME]                                  # Open the URL for a video call attached to your meeting at time TIME (default 'now')
  calendar-assistant location [DATE | DATERANGE]                  # Show your location for a date or range of dates (default 'today')
  calendar-assistant location-set LOCATION [DATE | DATERANGE]     # Set your location to LOCATION for a date or range of dates (default 'today')
  calendar-assistant show [DATE | DATERANGE | TIMERANGE]          # Show your events for a date or range of dates (default 'today')

Options:
  -h, -?, [--help], [--no-help]    
  -p, [--profile=PROFILE]          # the profile you'd like to use (if different from default)
          [--debug], [--no-debug]  # how dare you suggest there are bugs
</pre>


### View your configuration parameters

Calendar Assistant has intelligent defaults, which can be overridden in the TOML file `~/.calendar-assistant`, and further overridden via command-line parameters. Sometimes it's nice to be able to see what defaults Calendar Assistant is using:

<pre>
<b>$</b> calendar-assistant help config
Usage:
  calendar-assistant config

Options:
  -h, -?, [--help], [--no-help]    
  -p, [--profile=PROFILE]          # the profile you'd like to use (if different from default)
          [--debug], [--no-debug]  # how dare you suggest there are bugs

Dump your configuration parameters (merge of defaults and overrides from /home/flavorjones/.calendar-assistant)
</pre>

The output is TOML, which is suitable for dumping into `~/.calendar-assistant` and editing.

<pre>
<b>$</b> calendar-assistant config

[settings]
end-of-day = "6pm"
meeting-length = "30m"
profile = "work"
start-of-day = "9am"
</pre>


### Authorize access to your Google Calendar

<pre>
<b>$</b> calendar-assistant help authorize
Usage:
  calendar-assistant authorize PROFILE_NAME

Options:
  -h, -?, [--help], [--no-help]    
  -p, [--profile=PROFILE]          # the profile you'd like to use (if different from default)
          [--debug], [--no-debug]  # how dare you suggest there are bugs

Description:
  Create and authorize a named profile (e.g., "work", "home", "me@example.com") to access your calendar.

  When setting up a profile, you'll be asked to visit a URL to authenticate, grant authorization, and generate and persist an access token.

  In order for this to work, you'll need to follow the instructions at this URL first:

  > https://developers.google.com/calendar/quickstart/ruby

  Namely, the prerequisites are: 
   1. Turn on the Google API for your account 
   2. Create a new Google API Project 
   3. Download the configuration file for the Project, and name it as `credentials.json`
</pre>

This command will generate a URL which you should load in your browser while logged in as the Google account you wish to authorize. Generate a token, and paste the token back into `calendar-assistant`.

Your access token will be stored in `~/.calendar-assistant` in the `[tokens]` section.


### Display your calendar events

<pre>
<b>$</b> calendar-assistant help show
Usage:
  calendar-assistant show [DATE | DATERANGE | TIMERANGE]

Options:
  -c, [--commitments], [--no-commitments]  # only show events that you've accepted with another person
  -h, -?, [--help], [--no-help]            
  -p, [--profile=PROFILE]                  # the profile you'd like to use (if different from default)
          [--debug], [--no-debug]          # how dare you suggest there are bugs

Show your events for a date or range of dates (default 'today')
</pre>

For example: display all events scheduled for tomorrow:

<pre>
<b>$</b> calendar-assistant show --profile=work 2018-10-01
<i>me@example.com (all times in America/New_York)
</i>
2018-10-01               <b> | 🗺 Mines of Moria </b><i> (not-busy, self)</i>
<strike>2018-10-01  03:30 - 05:00 | Generate enterprise portals </strike>
<strike>2018-10-01  07:30 - 08:30 | Incentivize wireless functionalities </strike>
<strike>2018-10-01  07:30 - 08:30 | Brand end-to-end action-items </strike>
2018-10-01  08:00 - 09:00<b> | Grow web-enabled synergies </b><i> (recurring, self)</i>
2018-10-01  09:00 - 10:30<b> | Disintermediate integrated web services </b><i> (self)</i>
2018-10-01  10:30 - 10:55<b> | Architect sticky synergies </b><i> (1:1, recurring)</i>
2018-10-01  11:00 - 11:30<b> | Leverage out-of-the-box supply-chains </b><i> (recurring)</i>
2018-10-01  11:30 - 12:00<b> | Architect dot-com portals </b><i> (1:1, recurring)</i>
<strike>2018-10-01  11:50 - 12:00 | Grow out-of-the-box convergence </strike>
2018-10-01  12:00 - 12:30<b> | Morph leading-edge experiences </b><i> (self)</i>
<strike>2018-10-01  12:15 - 12:30 | Revolutionize innovative communities </strike>
<strike>2018-10-01  12:30 - 13:30 | Evolve mission-critical e-services </strike>
2018-10-01  12:30 - 13:30<b> | Embrace world-class e-tailers </b><i> (recurring)</i>
2018-10-01  13:30 - 14:50<b> | Deliver out-of-the-box infomediaries </b><i> (self)</i>
<strike>2018-10-01  13:30 - 14:30 | Transform user-centric e-tailers </strike>
2018-10-01  15:00 - 15:30<b> | Aggregate magnetic e-business </b><i> (1:1)</i>
2018-10-01  16:00 - 17:00<b> | Leverage turn-key e-tailers </b><i> (1:1, recurring)</i>
2018-10-01  16:45 - 17:00<b> | Monetize real-time interfaces </b><i> (recurring)</i>
2018-10-01  17:00 - 17:30<b> | Generate out-of-the-box technologies </b><i> (recurring)</i>
2018-10-01  17:30 - 17:55<b> | Strategize enterprise communities </b><i> (1:1, recurring)</i>
<strike>2018-10-01  18:00 - 20:30 | Redefine 24/365 infrastructures </strike>
<strike>2018-10-01  18:30 - 19:00 | Innovate vertical e-business </strike>
<strike>2018-10-01  19:00 - 19:30 | Repurpose seamless deliverables </strike>
</pre>

Display _only_ the commitments I have to other people using the `-c` option:

<pre>
<b>$</b> calendar-assistant show -c 2018-10-01
<i>me@example.com (all times in America/New_York)
</i>
2018-10-01  10:30 - 10:55<b> | Exploit b2b synergies </b><i> (1:1, recurring)</i>
2018-10-01  11:00 - 11:30<b> | Reinvent customized systems </b><i> (recurring)</i>
2018-10-01  11:30 - 12:00<b> | Incentivize visionary users </b><i> (1:1, recurring)</i>
2018-10-01  12:30 - 13:30<b> | Engineer robust roi </b><i> (recurring)</i>
2018-10-01  15:00 - 15:30<b> | Exploit next-generation content </b><i> (1:1)</i>
2018-10-01  16:00 - 17:00<b> | Integrate sticky platforms </b><i> (1:1, recurring)</i>
2018-10-01  16:45 - 17:00<b> | Enhance intuitive portals </b><i> (recurring)</i>
2018-10-01  17:00 - 17:30<b> | Reinvent viral platforms </b><i> (recurring)</i>
2018-10-01  17:30 - 17:55<b> | Incubate magnetic interfaces </b><i> (1:1, recurring)</i>
</pre>


### Join a video call attached to a meeting

<pre>
<b>$</b> calendar-assistant help join
Usage:
  calendar-assistant join [TIME]

Options:
          [--join], [--no-join]    # launch a browser to join the video call URL
                                   # Default: true
  -h, -?, [--help], [--no-help]    
  -p, [--profile=PROFILE]          # the profile you'd like to use (if different from default)
          [--debug], [--no-debug]  # how dare you suggest there are bugs

Open the URL for a video call attached to your meeting at time TIME (default 'now')
</pre>

Some examples:

<pre>
<b>$</b> calendar-assistant join
2018-09-28  11:30 - 12:00 | Status Meeting (recurring)
https://pivotal.zoom.us/j/ABC90210
# ... and opens the URL, which is associated with an event happening now

<b>$</b> calendar-assistant join work --no-join 11:30
2018-09-28  11:30 - 12:00 | Status Meeting (recurring)
https://pivotal.zoom.us/j/ABC90210
# ... and does not open the URL
</pre>


### Find your availability for meetings

This is useful for emailing people your availability. It only considers `accepted` meetings when determining busy/free.

<pre>
<b>$</b> calendar-assistant help availability
Usage:
  calendar-assistant availability [DATE | DATERANGE | TIMERANGE]

Options:
  -l, [--meeting-length=LENGTH]    # [default 30m] find chunks of available time at least as long as LENGTH (which is a ChronicDuration string like '30m' or '2h')
  -s, [--start-of-day=TIME]        # [default 9am] find chunks of available time after TIME (which is a Chronic string like '9am' or '14:30')
  -e, [--end-of-day=TIME]          # [default 6pm] find chunks of available time before TIME (which is a Chronic string like '9am' or '14:30')
  -h, -?, [--help], [--no-help]    
  -p, [--profile=PROFILE]          # the profile you'd like to use (if different from default)
          [--debug], [--no-debug]  # how dare you suggest there are bugs

Show your availability for a date or range of dates (default 'today')
</pre>


For example: show me my available time over a chunk of time:

<pre>
<b>$</b> calendar-assistant avail 2018-10-02..2018-10-04
<i>me@example.com
- all times in America/New_York
- looking for blocks at least 30 mins long
</i>
<b>Availability on Tuesday, October 2:
</b>
 • 11:25am - 12:00pm
 • 1:30pm - 3:00pm
 • 3:30pm - 4:00pm

<b>Availability on Wednesday, October 3:
</b>
 • 9:00am - 10:30am
 • 11:00am - 1:30pm
 • 1:55pm - 2:30pm
 • 2:55pm - 3:30pm

<b>Availability on Thursday, October 4:
</b>
 • 10:55am - 1:00pm
</pre>


You can also set start and end times for the search, which is useful when looking for overlap with another time zone:

<pre>
<b>$</b> calendar-assistant avail 2018-10-02..2018-10-04 -s 12pm -e 7pm
<i>me@example.com
- all times in America/New_York
- looking for blocks at least 30 mins long
</i>
<b>Availability on Tuesday, October 2:
</b>
 • 11:25am - 12:00pm
 • 1:30pm - 3:00pm
 • 3:30pm - 4:00pm
 • 6:25pm - 7:00pm

<b>Availability on Wednesday, October 3:
</b>
 • 11:00am - 1:30pm
 • 1:55pm - 2:30pm
 • 2:55pm - 3:30pm
 • 6:00pm - 7:00pm

<b>Availability on Thursday, October 4:
</b>
 • 10:55am - 1:00pm
 • 6:00pm - 7:00pm
</pre>


### Tell people where you are at in the world

Declare your location as an all-day non-busy event:

<pre>
<b>$</b> calendar-assistant help location-set
Usage:
  calendar-assistant location-set LOCATION [DATE | DATERANGE]

Options:
  -h, -?, [--help], [--no-help]    
  -p, [--profile=PROFILE]          # the profile you'd like to use (if different from default)
          [--debug], [--no-debug]  # how dare you suggest there are bugs

Set your location to LOCATION for a date or range of dates (default 'today')
</pre>

**Note** that you can only be in one place at a time, so existing location events may be modified or deleted when new overlapping events are created.

Some examples:

<pre>
# create an event titled `🗺 WFH` for today
<b>$</b> calendar-assistant location set -p home WFH
<b>Created:</b>
2018-09-03                | <b>🗺  WFH</b> (not-busy, self)

# create an event titled `🗺 OOO` for tomorrow
<b>$</b> calendar-assistant location-set OOO tomorrow
<b>Created:</b>
2018-09-04                | <b>🗺  OOO</b> (not-busy, self)

# create an event titled `🗺 Spring One` on the days of that conference
<b>$</b> calendar-assistant location-set "Spring One" 2018-09-24...2018-09-27
<b>Created:</b>
2018-09-24 - 2018-09-27   | <b>🗺  Spring One</b> (not-busy, self)

# create a vacation event for next week
<b>$</b> calendar-assistant location-set "Vacation!" "next monday ... next week friday"
<b>Created:</b>
2018-09-10 - 2018-09-14   | <b>🗺  Vacation!</b> (not-busy, self)
</pre>


### Look up where you're going to be

<pre>
<b>$</b> calendar-assistant help location
Usage:
  calendar-assistant location [DATE | DATERANGE]

Options:
  -h, -?, [--help], [--no-help]    
  -p, [--profile=PROFILE]          # the profile you'd like to use (if different from default)
          [--debug], [--no-debug]  # how dare you suggest there are bugs

Show your location for a date or range of dates (default 'today')
</pre>

For example:

<pre>
<b>$</b> calendar-assistant location "2018-09-24...2018-09-28"
<i>me@example.com (all times in America/New_York)
</i>
2018-09-24 - 2018-09-27  <b> | 🗺 Grey Mountains </b><i> (not-busy, self)</i>
2018-09-28               <b> | 🗺 Dorwinion </b><i> (not-busy, self)</i>
</pre>


## References

Google Calendar Concepts: https://developers.google.com/calendar/concepts/

Google's API docs: https://www.rubydoc.info/github/google/google-api-ruby-client/Google/Apis/CalendarV3

Recurrence: https://github.com/seejohnrun/ice_cube


## License

See files `LICENSE` and `NOTICE` in this repository.
