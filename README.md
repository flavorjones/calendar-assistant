# calendar assistant

A command-line tool to help you manage your Google Calendar.

- easily join the videoconference for your current meeting
- see yours and others' "availability" suitable for an email response
- set up all-day events to let people know where you are (for frequent travelers)
- see views on your calendar events for a date or time range
- book (and re-book) one-on-ones and other meetings automatically

[![Concourse CI](https://ci.nokogiri.org/api/v1/teams/calendar-assistants/pipelines/calendar-assistant/jobs/rake-spec/badge)](https://ci.nokogiri.org/teams/calendar-assistants/pipelines/calendar-assistant)
[![Maintainability](https://api.codeclimate.com/v1/badges/3525792e1feeccfd8875/maintainability)](https://codeclimate.com/github/flavorjones/calendar-assistant/maintainability)

<!-- toc -->

- [Features](#features)
  * [Pretty Display in Your Terminal](#pretty-display-in-your-terminal)
  * [Human-Friendly Date and Time Specification](#human-friendly-date-and-time-specification)
  * [Human-Friendly Duration Specification](#human-friendly-duration-specification)
  * [Preferences](#preferences)
- [Setup](#setup)
  * [Installation](#installation)
  * [Set up a Google Cloud Project with API access](#set-up-a-google-cloud-project-with-api-access)
  * [Authorize access to your Google Calendar](#authorize-access-to-your-google-calendar)
- [Commands](#commands)
  * [Join a video call attached to a meeting](#join-a-video-call-attached-to-a-meeting)
  * [Find your availability for meetings](#find-your-availability-for-meetings)
  * [Tell people where you are at in the world](#tell-people-where-you-are-at-in-the-world)
  * [Look up where you're going to be](#look-up-where-youre-going-to-be)
  * [Display your calendar events](#display-your-calendar-events)
  * [View your configuration parameters](#view-your-configuration-parameters)
- [References](#references)
- [License](#license)

<!-- tocstop -->

## Features

### Pretty Display in Your Terminal

Events are nicely formatted, with faint strikeouts for events you've declined, and some additional attributes listed when present (e.g., "awaiting", "self", "not-busy", "1:1" ...)


### Human-Friendly Date and Time Specification

All dates and times are interpreted by [Chronic](https://github.com/mojombo/chronic) and so can be fuzzy terms like "tomorrow", "tuesday", "next thursday", and "two days from now" as well as specific dates and times.

For a date range or a datetime range, split the start and end with `..` or `...` (with or without spaces) like:

* "tomorrow ... three days from now"
* "2018-09-24..2018-09-27".

Also note that every command will adopt an intelligent default, which is generally "today" or "now".


### Human-Friendly Duration Specification

Some duration-related preferences are interpreted by [ChronicDuration](https://github.com/henrypoydar/chronic_duration) and so can be terms like "10m", "30 minutes", "four hours", etc.


### Preferences

All tokens and preferences will be stored in `~/.calendar-assistant` which is in TOML format for easy editing.


## Setup

### Installation

Install the gem: `gem install calendar-assistant`.


### Set up a Google Cloud Project with API access

<pre>
Usage:
  calendar-assistant setup

Options:
          [--local-store=LOCAL_STORE]  # filename of local store
  -h, -?, [--help], [--no-help]        
          [--debug], [--no-debug]      # how dare you suggest there are bugs

Description:
  This command will walk you through setting up a Google Cloud Project, enabling the Google Calendar
  API, and saving the credentials necessary to access the API on behalf of users.

  If you already have downloaded client credentials, you don't need to run this command. Instead,
  rename the downloaded JSON file to `/home/flavorjones/.calendar-assistant.client`
</pre>


### Authorize access to your Google Calendar

<pre>
Usage:
  calendar-assistant authorize PROFILE_NAME

Options:
          [--local-store=LOCAL_STORE]  # filename of local store
  -h, -?, [--help], [--no-help]        
          [--debug], [--no-debug]      # how dare you suggest there are bugs

Description:
  Create and authorize a named profile (e.g., "work", "home", "me@example.com") to access your
  calendar.

  When setting up a profile, you'll be asked to visit a URL to authenticate, grant authorization, and
  generate and persist an access token.

  In order for this to work, you'll need to have set up your API client credentials. Run
  `calendar-assistant help setup` for instructions.
</pre>


## Commands

<pre>
Commands:
  calendar-assistant authorize PROFILE_NAME                       # create (or validate) a profil...
  calendar-assistant availability [DATE | DATERANGE | TIMERANGE]  # Show your availability for a ...
  calendar-assistant config                                       # Dump your configuration param...
  calendar-assistant help [COMMAND]                               # Describe available commands o...
  calendar-assistant join [TIME]                                  # Open the URL for a video call...
  calendar-assistant location [DATE | DATERANGE]                  # Show your location for a date...
  calendar-assistant location-set LOCATION [DATE | DATERANGE]     # Set your location to LOCATION...
  calendar-assistant setup                                        # Link your local calendar-assi...
  calendar-assistant show [DATE | DATERANGE | TIMERANGE]          # Show your events for a date o...
  calendar-assistant version                                      # Display the version of calend...

Options:
          [--local-store=LOCAL_STORE]  # filename of local store
  -h, -?, [--help], [--no-help]        
          [--debug], [--no-debug]      # how dare you suggest there are bugs
</pre>


### Join a video call attached to a meeting

<pre>
Usage:
  calendar-assistant join [TIME]

Options:
          [--join], [--no-join]        # launch a browser to join the video call URL
                                       # Default: true
  -p, [--profile=PROFILE]              # the profile you'd like to use (if different from default)
          [--local-store=LOCAL_STORE]  # filename of local store
  -h, -?, [--help], [--no-help]        
          [--debug], [--no-debug]      # how dare you suggest there are bugs

Open the URL for a video call attached to your meeting at time TIME (default 'now')
</pre>

Some examples:

<pre>
<b>$</b> calendar-assistant join
2018-09-28  11:30 - 12:00 | Status Meeting (recurring)
https://pivotal.zoom.us/j/ABC90210
<i># ... and opens the URL, which is associated with an event happening now</i>

<b>$</b> calendar-assistant join work 11:30 --no-join 
2018-09-28  11:30 - 12:00 | Status Meeting (recurring)
https://pivotal.zoom.us/j/ABC90210
<i># ... and does not open the URL</i>
</pre>


### Find your availability for meetings

This is useful for emailing people your availability. It only considers `accepted` meetings when determining busy/free.

<pre>
Usage:
  calendar-assistant availability [DATE | DATERANGE | TIMERANGE]

Options:
  -l, [--meeting-length=LENGTH]        # [default 30m] find chunks of available time at least as long as LENGTH (which is a ChronicDuration string like '30m' or '2h')
  -s, [--start-of-day=TIME]            # [default 9am] find chunks of available time after TIME (which is a BusinessTime string like '9am' or '14:30')
  -e, [--end-of-day=TIME]              # [default 6pm] find chunks of available time before TIME (which is a BusinessTime string like '9am' or '14:30')
  -z, [--timezone=TIMEZONE]            # [default is calendar tz] find chunks of available time in TIMEZONE (e.g., 'America/New_York')
  -p, [--profile=PROFILE]              # the profile you'd like to use (if different from default)
          [--local-store=LOCAL_STORE]  # filename of local store
  -h, -?, [--help], [--no-help]        
          [--debug], [--no-debug]      # how dare you suggest there are bugs

Show your availability for a date or range of dates (default 'today')
</pre>


For example: show me my available time over a chunk of time:

<pre>
<b>$</b> calendar-assistant avail 2018-10-02..2018-10-04
<i>me@example.com
- all times in America/New_York
- looking for blocks at least 30 mins long
- between 9am and 6pm in America/New_York
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
- between 12pm and 7pm in America/New_York
</i>
<b>Availability on Tuesday, October 2:
</b>
 • 1:30pm - 3:00pm
 • 3:30pm - 4:00pm
 • 6:25pm - 7:00pm

<b>Availability on Wednesday, October 3:
</b>
 • 12:00pm - 1:30pm
 • 1:55pm - 2:30pm
 • 2:55pm - 3:30pm
 • 6:00pm - 7:00pm

<b>Availability on Thursday, October 4:
</b>
 • 12:00pm - 1:00pm
 • 6:00pm - 7:00pm
</pre>


### Tell people where you are at in the world

Declare your location as an all-day non-busy event:

<pre>
Usage:
  calendar-assistant location-set LOCATION [DATE | DATERANGE]

Options:
  -p, [--profile=PROFILE]              # the profile you'd like to use (if different from default)
          [--local-store=LOCAL_STORE]  # filename of local store
  -h, -?, [--help], [--no-help]        
          [--debug], [--no-debug]      # how dare you suggest there are bugs

Set your location to LOCATION for a date or range of dates (default 'today')
</pre>

**Note** that you can only be in one place at a time, so existing location events may be modified or deleted when new overlapping events are created.

Some examples:

<pre>
<i># create an event titled `🗺 WFH` for today</i>
<b>$</b> calendar-assistant location set -p home WFH
<b>Created:</b>
2018-09-03                | <b>🗺  WFH</b> (not-busy, self)

<i># create an event titled `🗺 OOO` for tomorrow</i>
<b>$</b> calendar-assistant location-set OOO tomorrow
<b>Created:</b>
2018-09-04                | <b>🗺  OOO</b> (not-busy, self)

<i># create an event titled `🗺 Spring One` on the days of that conference</i>
<b>$</b> calendar-assistant location-set "Spring One" 2018-09-24...2018-09-27
<b>Created:</b>
2018-09-24 - 2018-09-27   | <b>🗺  Spring One</b> (not-busy, self)

<i># create a vacation event for next week</i>
<b>$</b> calendar-assistant location-set "Vacation!" "next monday ... next week friday"
<b>Created:</b>
2018-09-10 - 2018-09-14   | <b>🗺  Vacation!</b> (not-busy, self)
</pre>


### Look up where you're going to be

<pre>
Usage:
  calendar-assistant location [DATE | DATERANGE]

Options:
  -p, [--profile=PROFILE]              # the profile you'd like to use (if different from default)
          [--local-store=LOCAL_STORE]  # filename of local store
  -h, -?, [--help], [--no-help]        
          [--debug], [--no-debug]      # how dare you suggest there are bugs

Show your location for a date or range of dates (default 'today')
</pre>

For example:

<pre>
<b>$</b> calendar-assistant location "2018-09-24...2018-09-28"
<i>me@example.com (all times in America/New_York)
</i>
2018-09-24 - 2018-09-27  <b> | 🗺 The Great Mill </b><i> (not-busy, self)</i>
2018-09-28               <b> | 🗺 Land Beyond </b><i> (not-busy, self)</i>
</pre>


### Display your calendar events

<pre>
Usage:
  calendar-assistant show [DATE | DATERANGE | TIMERANGE]

Options:
  -c, [--commitments], [--no-commitments]  # only show events that you've accepted with another person
  -p, [--profile=PROFILE]                  # the profile you'd like to use (if different from default)
          [--local-store=LOCAL_STORE]      # filename of local store
  -h, -?, [--help], [--no-help]            
          [--debug], [--no-debug]          # how dare you suggest there are bugs

Show your events for a date or range of dates (default 'today')
</pre>

For example: display all events scheduled for tomorrow:

<pre>
<b>$</b> calendar-assistant show --profile=work 2018-10-01
<i>me@example.com (all times in America/New_York)
</i>
2018-10-01               <b> | 🗺 The Great Mill </b><i> (not-busy, self)</i>
<strike>2018-10-01  03:30 - 05:00 | E-enable collaborative communities </strike>
<strike>2018-10-01  07:30 - 08:30 | Morph next-generation bandwidth </strike>
<strike>2018-10-01  07:30 - 08:30 | Maximize compelling networks </strike>
2018-10-01  08:00 - 09:00<b> | Recontextualize integrated interfaces </b><i> (recurring, self)</i>
2018-10-01  09:00 - 10:30<b> | Syndicate web-enabled content </b><i> (self)</i>
2018-10-01  10:30 - 10:55<b> | Iterate efficient methodologies </b><i> (1:1, recurring)</i>
2018-10-01  11:00 - 11:30<b> | Benchmark next-generation infomediaries </b><i> (recurring)</i>
2018-10-01  11:30 - 12:00<b> | Reinvent web-enabled infomediaries </b><i> (1:1, recurring)</i>
<strike>2018-10-01  11:50 - 12:00 | Incentivize customized experiences </strike>
2018-10-01  12:00 - 12:30<b> | Visualize clicks-and-mortar functionalities </b><i> (self)</i>
<strike>2018-10-01  12:15 - 12:30 | Transition efficient e-commerce </strike>
<strike>2018-10-01  12:30 - 13:30 | Target proactive e-services </strike>
2018-10-01  12:30 - 13:30<b> | Innovate leading-edge systems </b><i> (recurring)</i>
2018-10-01  13:30 - 14:50<b> | Evolve 24/7 deliverables </b><i> (self)</i>
<strike>2018-10-01  13:30 - 14:30 | Leverage bleeding-edge applications </strike>
2018-10-01  15:00 - 15:30<b> | Redefine open-source metrics </b><i> (1:1)</i>
2018-10-01  16:00 - 17:00<b> | Extend magnetic systems </b><i> (1:1, recurring)</i>
2018-10-01  16:45 - 17:00<b> | Aggregate e-business metrics </b><i> (recurring)</i>
2018-10-01  17:00 - 17:30<b> | Matrix distributed interfaces </b><i> (recurring)</i>
2018-10-01  17:30 - 17:55<b> | Synthesize vertical niches </b><i> (1:1, recurring)</i>
<strike>2018-10-01  18:00 - 20:30 | Matrix out-of-the-box web services </strike>
<strike>2018-10-01  18:30 - 19:00 | Mesh innovative mindshare </strike>
<strike>2018-10-01  19:00 - 19:30 | Optimize world-class paradigms </strike>
</pre>

Display _only_ the commitments I have to other people using the `-c` option:

<pre>
<b>$</b> calendar-assistant show -c 2018-10-01
<i>me@example.com (all times in America/New_York)
</i>
2018-10-01  10:30 - 10:55<b> | Maximize interactive e-commerce </b><i> (1:1, recurring)</i>
2018-10-01  11:00 - 11:30<b> | Incubate innovative content </b><i> (recurring)</i>
2018-10-01  11:30 - 12:00<b> | Extend virtual content </b><i> (1:1, recurring)</i>
2018-10-01  12:30 - 13:30<b> | Innovate proactive content </b><i> (recurring)</i>
2018-10-01  15:00 - 15:30<b> | Transform seamless systems </b><i> (1:1)</i>
2018-10-01  16:00 - 17:00<b> | Architect granular mindshare </b><i> (1:1, recurring)</i>
2018-10-01  16:45 - 17:00<b> | Cultivate turn-key initiatives </b><i> (recurring)</i>
2018-10-01  17:00 - 17:30<b> | Synergize next-generation supply-chains </b><i> (recurring)</i>
2018-10-01  17:30 - 17:55<b> | Seize global vortals </b><i> (1:1, recurring)</i>
</pre>


### View your configuration parameters

Calendar Assistant has intelligent defaults, which can be overridden in the TOML file `~/.calendar-assistant`, and further overridden via command-line parameters. Sometimes it's nice to be able to see what defaults Calendar Assistant is using:

<pre>
Usage:
  calendar-assistant config

Options:
          [--local-store=LOCAL_STORE]  # filename of local store
  -h, -?, [--help], [--no-help]        
          [--debug], [--no-debug]      # how dare you suggest there are bugs

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


## References

Google Calendar Concepts: https://developers.google.com/calendar/concepts/

Google's API docs: https://www.rubydoc.info/github/google/google-api-ruby-client/Google/Apis/CalendarV3

Recurrence: https://github.com/seejohnrun/ice_cube


## License

See files `LICENSE` and `NOTICE` in this repository.
