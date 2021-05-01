<img src="icons/calendar-assistant.png" align="right" />

# Calendar Assistant
>A command-line tool to help you manage your Google Calendar.

- easily join the videoconference for your current meeting
- see yours and others' "availability" suitable for an email response
- set up all-day events to let people know where you are (for frequent travelers)
- see views on your calendar events for a date or time range
- book (and re-book) one-on-ones and other meetings automatically

[![Gem Version](https://badge.fury.io/rb/calendar-assistant.svg)](https://badge.fury.io/rb/calendar-assistant)
[![Test suite](https://github.com/flavorjones/calendar-assistant/actions/workflows/test-suite.yml/badge.svg)](https://github.com/flavorjones/calendar-assistant/actions/workflows/test-suite.yml)
[![Maintainability](https://api.codeclimate.com/v1/badges/3525792e1feeccfd8875/maintainability)](https://codeclimate.com/github/flavorjones/calendar-assistant/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/3525792e1feeccfd8875/test_coverage)](https://codeclimate.com/github/flavorjones/calendar-assistant/test_coverage)
[![Join the chat at https://gitter.im/flavorjones/calendar-assistant](https://badges.gitter.im/flavorjones/calendar-assistant.svg)](https://gitter.im/flavorjones/calendar-assistant?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

## Contents

<!-- toc -->

- [Features](#features)
  * [Pretty Display in Your Terminal](#pretty-display-in-your-terminal)
  * [Human-Friendly Date and Time Specification](#human-friendly-date-and-time-specification)
  * [Human-Friendly Duration Specification](#human-friendly-duration-specification)
  * [Filter Events by property](#filter-events-by-property)
  * [Preferences](#preferences)
- [Setup](#setup)
  * [Installation](#installation)
  * [Set up a Google Cloud Project with API access](#set-up-a-google-cloud-project-with-api-access)
  * [Authorize access to your Google Calendar](#authorize-access-to-your-google-calendar)
- [Commands](#commands)
  * [`join`: Join a video call attached to a meeting](#join-join-a-video-call-attached-to-a-meeting)
  * [`availability`: Find people's availability for meetings](#availability-find-peoples-availability-for-meetings)
  * [`location-set`: Tell people where you are in the world](#location-set-tell-people-where-you-are-in-the-world)
  * [`location`: View where you're going to be in the world](#location-view-where-youre-going-to-be-in-the-world)
  * [`show`: View your calendar events](#show-view-your-calendar-events)
  * [`lint`: Calendar events that require action](#lint-calendar-events-that-require-action)
  * [`config`: View your configuration parameters](#config-view-your-configuration-parameters)
  * [`interactive`: Interactive Console](#interactive-interactive-console)
- [Development](#development)
  * [Running Tests Locally](#running-tests-locally)
  * [Continuous Integration](#continuous-integration)
  * [Code Quality](#code-quality)
  * [Generate README](#generate-readme)
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

### Filter Events by property

Commands that return events like `show`, `join`, `availability`, `location` or `lint` can be filtered using the option `--must-be` or `--must-not-be`. These options expect a comma separated list of one of the following properties.

* **Response**
	* `accepted`
	* `declined`
	* `awaiting`
	* `tentative`
* **Temporal**
	* `all_day`
	* `past`
	* `current`
	* `future`
* **Visibility**
	* `private`
	* `public`
	* `explicitly_visible`
	* `visible_guestlist`
* **Attributes**
	* `location_event`
	* `self`
	* `one_on_one`
	* `busy`
	* `commitment`
	* `recurring`
	* `abandoned`
	* `anyone_can_add_self`
	* `attendees_omitted`
	* `end_time_unspecified`
	* `guests_can_invite_others`
	* `guests_can_modify`
	* `guests_can_see_other_guests`
	* `private_copy`
	* `locked`
	* `needs_action`


### Preferences

All tokens and preferences will be stored in `~/.calendar-assistant` which is in TOML format for easy editing.

The location of `.calendar-assistant` defaults to the user's home directory. This location may be overridden by setting the environment variable `CA_HOME`


#### Nickname

Some commands, like `location-set`, will refer to you by nickname if you configure it (the alternative might be to not specify your name, or use your email id).

Set `nickname` to a string that would uniquely and briefly identify you to others, like "Mike D" or "JK".

#### Location Emoji

There is a `[settings]` key called `location-icon` that may be set to an emoji denoting a location event. By default CalendarAssistant will use `"🌎"`, but you can change this.


#### Command-Specific Preferences

If there are user preferences you'd like to set for just a single command (e.g., making public location events created via `location-set`), you can create a nested section in your TOML settings file, like so:

```toml
[settings]
visibility = "default"
nickname = "uniquely-me"

[settings.location_set]
visibility = "public"
calendars = ["teamcalendar@group.calendar.google.com","teamcalendar2@group.calendar.google.com"]
```


## Setup

### Installation

Install the gem: `gem install calendar-assistant`.


### Set up a Google Cloud Project with API access

<pre>
Usage:
  calendar-assistant setup

Options:
  -h, -?, [--help], [--no-help]          
          [--debug], [--no-debug]        # how dare you suggest there are bugs
  -f, [--formatting], [--no-formatting]  # Enable Text Formatting
                                         # Default: true

Description:
  This command will walk you through setting up a Google Cloud Project, enabling the Google Calendar API, and saving
  the credentials necessary to access the API on behalf of users.

  If you already have downloaded client credentials, you don't need to run this command. Instead, rename the downloaded
  JSON file to `/home/user/.calendar-assistant.client`
</pre>


### Authorize access to your Google Calendar

<pre>
Usage:
  calendar-assistant authorize PROFILE_NAME

Options:
  -h, -?, [--help], [--no-help]          
          [--debug], [--no-debug]        # how dare you suggest there are bugs
  -f, [--formatting], [--no-formatting]  # Enable Text Formatting
                                         # Default: true

Description:
  Create and authorize a named profile (e.g., "work", "home", "flastname@company.tld") to access your calendar.

  When setting up a profile, you'll be asked to visit a URL to authenticate, grant authorization, and generate and
  persist an access token.

  In order for this to work, you'll need to have set up your API client credentials. Run `calendar-assistant help
  setup` for instructions.
</pre>


## Commands

<pre>
Commands:
  calendar-assistant authorize PROFILE_NAME                       # create (or validate) a profile named NAME with ca...
  calendar-assistant availability [DATE | DATERANGE | TIMERANGE]  # Show your availability for a date or range of dat...
  calendar-assistant config                                       # Dump your configuration parameters (merge of defa...
  calendar-assistant help [COMMAND]                               # Describe available commands or one specific command
  calendar-assistant interactive                                  # interactive console for calendar assistant
  calendar-assistant join [TIME]                                  # Open the URL for a video call attached to your me...
  calendar-assistant lint [DATE | DATERANGE | TIMERANGE]          # Lint your events for a date or range of dates (de...
  calendar-assistant location [DATE | DATERANGE]                  # Show your location for a date or range of dates (...
  calendar-assistant location-set LOCATION [DATE | DATERANGE]     # Set your location to LOCATION for a date or range...
  calendar-assistant setup                                        # Link your local calendar-assistant installation t...
  calendar-assistant show [DATE | DATERANGE | TIMERANGE]          # Show your events for a date or range of dates (de...
  calendar-assistant version                                      # Display the version of calendar-assistant

Options:
  -h, -?, [--help], [--no-help]          
          [--debug], [--no-debug]        # how dare you suggest there are bugs
  -f, [--formatting], [--no-formatting]  # Enable Text Formatting
                                         # Default: true
</pre>


### `join`: Join a video call attached to a meeting

<pre>
Usage:
  calendar-assistant join [TIME]

Options:
          [--join], [--no-join]                    # launch a browser to join the video call URL
                                                   # Default: true
  -p, [--profile=PROFILE]                          # the profile you'd like to use (if different from default)
  -l, [--local-store=FILENAME]                     # Load events from a local file instead of Google Calendar
  -b, [--must-be=PROPERTY1[,PROPERTY2[,...]]]      # Event properties that must be true (see README)
  -n, [--must-not-be=PROPERTY1[,PROPERTY2[,...]]]  # Event properties that must be false (see README)
  -h, -?, [--help], [--no-help]                    
          [--debug], [--no-debug]                  # how dare you suggest there are bugs
  -f, [--formatting], [--no-formatting]            # Enable Text Formatting
                                                   # Default: true

Open the URL for a video call attached to your meeting at time TIME (default 'now')
</pre>

Some examples:

<pre>
<b>$</b> calendar-assistant join
<i>me@example.com</i>

2018-10-01  11:30 - 12:00<b> | Facilitate customized web-readiness </b><i> (1:1, recurring)</i>

https://pivotal.zoom.us/j/ABC90210 <i># ... and opens the videoconference URL</i>


<b>$</b> calendar-assistant join work 11:30 --no-join
<i>me@example.com</i>

2018-10-01  11:30 - 12:00<b> | Facilitate customized web-readiness </b><i> (1:1, recurring)</i>

https://pivotal.zoom.us/j/ABC90210 <i># ... and does not open the URL</i>
</pre>


### `availability`: Find people's availability for meetings

This is useful for emailing people your availability. It only considers `accepted` meetings when determining busy/free.

<pre>
Usage:
  calendar-assistant availability [DATE | DATERANGE | TIMERANGE]

Options:
  -l, [--meeting-length=LENGTH]                               # [default 30m] find chunks of available time at least as long as LENGTH (which is a ChronicDuration string like '30m' or '2h')
  -s, [--start-of-day=TIME]                                   # [default 9am] find chunks of available time after TIME (which is a BusinessTime string like '9am' or '14:30')
  -e, [--end-of-day=TIME]                                     # [default 6pm] find chunks of available time before TIME (which is a BusinessTime string like '9am' or '14:30')
  -a, --attendees, [--calendars=CALENDAR1[,CALENDAR2[,...]]]  # [default 'me'] people (email IDs) to whom this command will be applied
  -p, [--profile=PROFILE]                                     # the profile you'd like to use (if different from default)
  -l, [--local-store=FILENAME]                                # Load events from a local file instead of Google Calendar
  -b, [--must-be=PROPERTY1[,PROPERTY2[,...]]]                 # Event properties that must be true (see README)
  -n, [--must-not-be=PROPERTY1[,PROPERTY2[,...]]]             # Event properties that must be false (see README)
  -h, -?, [--help], [--no-help]                               
          [--debug], [--no-debug]                             # how dare you suggest there are bugs
  -f, [--formatting], [--no-formatting]                       # Enable Text Formatting
                                                              # Default: true

Show your availability for a date or range of dates (default 'today')
</pre>


For example: show me my available time over a chunk of time:

<pre>
<b>$</b> calendar-assistant avail 2018-11-05..2018-11-07
<i>me@example.com</i>
<i>- looking for blocks at least 30 mins long</i>
<i>- between 9am and 6pm in America/New_York</i>

<b>Availability on Monday, November 5:
</b>
 •  9:00am - 10:00am EST<i> (1h)</i>
 •  1:30pm -  2:30pm EST<i> (1h)</i>
 •  3:30pm -  5:00pm EST<i> (1h 30m)</i>
 •  5:30pm -  6:00pm EST<i> (30m)</i>

<b>Availability on Tuesday, November 6:
</b>
 •  9:00am -  4:30pm EST<i> (7h 30m)</i>
 •  4:50pm -  6:00pm EST<i> (1h 10m)</i>

<b>Availability on Wednesday, November 7:
</b>
 •  9:00am -  2:30pm EST<i> (5h 30m)</i>
 •  5:30pm -  6:00pm EST<i> (30m)</i>
</pre>


You can also find times when multiple people are available:

<pre>
<b>$</b> calendar-assistant avail 2018-11-05..2018-11-07 -a me@example.com,other@example.com
<i>me@example.com, other@example.com</i>
<i>- looking for blocks at least 30 mins long</i>
<i>- between 9am and 6pm in America/New_York</i>
<i>- between 9am and 6pm in America/Los_Angeles</i>

<b>Availability on Monday, November 5:
</b>
 •  4:30pm -  5:00pm EST /  1:30pm -  2:00pm PST<i> (30m)</i>

<b>Availability on Tuesday, November 6:
</b>
 • 12:00pm -  4:30pm EST /  9:00am -  1:30pm PST<i> (4h 30m)</i>
 •  4:50pm -  6:00pm EST /  1:50pm -  3:00pm PST<i> (1h 10m)</i>

<b>Availability on Wednesday, November 7:
</b>
 • 12:00pm -  2:30pm EST /  9:00am - 11:30am PST<i> (2h 30m)</i>
</pre>


You can also set start and end times for the search, which is useful when looking for overlap with another time zone:

<pre>
<b>$</b> calendar-assistant avail 2018-11-05..2018-11-07 -s 12pm -e 7pm
<i>me@example.com</i>
<i>- looking for blocks at least 30 mins long</i>
<i>- between 12pm and 7pm in America/New_York</i>

<b>Availability on Monday, November 5:
</b>
 •  1:30pm -  2:30pm EST<i> (1h)</i>
 •  3:30pm -  5:00pm EST<i> (1h 30m)</i>
 •  5:30pm -  7:00pm EST<i> (1h 30m)</i>

<b>Availability on Tuesday, November 6:
</b>
 • 12:00pm -  4:30pm EST<i> (4h 30m)</i>
 •  4:50pm -  7:00pm EST<i> (2h 10m)</i>

<b>Availability on Wednesday, November 7:
</b>
 • 12:00pm -  2:30pm EST<i> (2h 30m)</i>
 •  5:30pm -  7:00pm EST<i> (1h 30m)</i>
</pre>


### `location-set`: Tell people where you are in the world

Declare your location as an all-day non-busy event:

<pre>
Usage:
  calendar-assistant location-set LOCATION [DATE | DATERANGE]

Options:
          [--force]                                           # will manage location across multiple calendars whether a nickname is set or not
          [--visibility=VISIBILITY]                           # [default is 'default'] Set the visibility of the event. Values are 'public', 'private', 'default'.
  -p, [--profile=PROFILE]                                     # the profile you'd like to use (if different from default)
  -l, [--local-store=FILENAME]                                # Load events from a local file instead of Google Calendar
  -b, [--must-be=PROPERTY1[,PROPERTY2[,...]]]                 # Event properties that must be true (see README)
  -n, [--must-not-be=PROPERTY1[,PROPERTY2[,...]]]             # Event properties that must be false (see README)
  -a, --attendees, [--calendars=CALENDAR1[,CALENDAR2[,...]]]  # [default 'me'] people (email IDs) to whom this command will be applied
  -h, -?, [--help], [--no-help]                               
          [--debug], [--no-debug]                             # how dare you suggest there are bugs
  -f, [--formatting], [--no-formatting]                       # Enable Text Formatting
                                                              # Default: true

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


### `location`: View where you're going to be in the world

<pre>
Usage:
  calendar-assistant location [DATE | DATERANGE]

Options:
  -p, [--profile=PROFILE]                          # the profile you'd like to use (if different from default)
  -l, [--local-store=FILENAME]                     # Load events from a local file instead of Google Calendar
  -b, [--must-be=PROPERTY1[,PROPERTY2[,...]]]      # Event properties that must be true (see README)
  -n, [--must-not-be=PROPERTY1[,PROPERTY2[,...]]]  # Event properties that must be false (see README)
  -h, -?, [--help], [--no-help]                    
          [--debug], [--no-debug]                  # how dare you suggest there are bugs
  -f, [--formatting], [--no-formatting]            # Enable Text Formatting
                                                   # Default: true

Show your location for a date or range of dates (default 'today')
</pre>

For example:

<pre>
<b>$</b> calendar-assistant location "2018-09-24...2018-09-28"
<i>me@example.com (all times in America/New_York)
</i>
2018-09-24 - 2018-09-28  <b> | 🌎 Iron Hills</b><i> (not-busy)</i>
2018-09-28               <b> | 🌎 Country Round</b><i> (not-busy)</i>
</pre>


### `show`: View your calendar events

<pre>
Usage:
  calendar-assistant show [DATE | DATERANGE | TIMERANGE]

Options:
  -c, [--commitments], [--no-commitments]                     # only show events that you've accepted with another person
  -p, [--profile=PROFILE]                                     # the profile you'd like to use (if different from default)
  -l, [--local-store=FILENAME]                                # Load events from a local file instead of Google Calendar
  -a, --attendees, [--calendars=CALENDAR1[,CALENDAR2[,...]]]  # [default 'me'] people (email IDs) to whom this command will be applied
  -b, [--must-be=PROPERTY1[,PROPERTY2[,...]]]                 # Event properties that must be true (see README)
  -n, [--must-not-be=PROPERTY1[,PROPERTY2[,...]]]             # Event properties that must be false (see README)
  -h, -?, [--help], [--no-help]                               
          [--debug], [--no-debug]                             # how dare you suggest there are bugs
  -f, [--formatting], [--no-formatting]                       # Enable Text Formatting
                                                              # Default: true

Show your events for a date or range of dates (default 'today')
</pre>

For example: display all events scheduled for tomorrow:

<pre>
<b>$</b> calendar-assistant show 2018-10-01
<i>me@example.com (all times in America/New_York)
</i>
<strike>2018-10-01  03:30 - 05:00 | Facilitate 24/365 web services</strike>
<strike>2018-10-01  07:30 - 08:30 | Reintermediate magnetic communities</strike>
<strike>2018-10-01  07:30 - 08:30 | Revolutionize bricks-and-clicks synergies</strike>
2018-10-01  10:30 - 10:55<b> | Whiteboard clicks-and-mortar metrics</b><i> (1:1, recurring)</i>
2018-10-01  11:00 - 11:30<b> | Architect holistic models</b><i> (recurring)</i>
2018-10-01  11:30 - 12:00<b> | Reinvent bleeding-edge e-services</b><i> (1:1, recurring)</i>
2018-10-01  11:50 - 12:00<b> | Synergize e-business systems</b><i> (awaiting)</i>
2018-10-01  12:00 - 12:30<b> | Reinvent e-business e-tailers</b><i> (self)</i>
<strike>2018-10-01  12:15 - 12:30 | Maximize clicks-and-mortar convergence</strike>
<strike>2018-10-01  12:30 - 13:30 | Disintermediate end-to-end bandwidth</strike>
2018-10-01  12:30 - 13:30<b> | Iterate innovative networks</b><i> (awaiting, recurring)</i>
2018-10-01  13:30 - 14:50<b> | Engage holistic users</b><i> (self)</i>
<strike>2018-10-01  13:30 - 14:30 | Enable e-business e-services</strike>
2018-10-01  15:00 - 15:30<b> | Innovate impactful technologies</b><i> (1:1)</i>
2018-10-01  16:00 - 17:00<b> | Iterate dynamic networks</b><i> (1:1, recurring)</i>
2018-10-01  16:45 - 17:00<b> | Deploy robust content</b><i> (recurring)</i>
2018-10-01  17:00 - 17:30<b> | Synthesize viral methodologies</b><i> (recurring)</i>
2018-10-01  17:30 - 17:55<b> | Scale collaborative methodologies</b><i> (1:1, recurring)</i>
<strike>2018-10-01  18:00 - 20:30 | Seize rich experiences</strike>
<strike>2018-10-01  18:30 - 19:00 | Engineer one-to-one e-business</strike>
2018-10-01  19:00 - 19:30<b> | Recontextualize collaborative content</b><i> (awaiting)</i>
2018-10-01               <b> | 🌎 Grey Mountains</b><i> (not-busy)</i>
</pre>

Display _only_ the commitments I have to other people using the `-c` option:

<pre>
<b>$</b> calendar-assistant show -c 2018-10-01
<i>me@example.com (all times in America/New_York)
</i>
2018-10-01  10:30 - 10:55<b> | Whiteboard clicks-and-mortar metrics</b><i> (1:1, recurring)</i>
2018-10-01  11:00 - 11:30<b> | Architect holistic models</b><i> (recurring)</i>
2018-10-01  11:30 - 12:00<b> | Reinvent bleeding-edge e-services</b><i> (1:1, recurring)</i>
2018-10-01  11:50 - 12:00<b> | Synergize e-business systems</b><i> (awaiting)</i>
2018-10-01  12:30 - 13:30<b> | Iterate innovative networks</b><i> (awaiting, recurring)</i>
2018-10-01  15:00 - 15:30<b> | Innovate impactful technologies</b><i> (1:1)</i>
2018-10-01  16:00 - 17:00<b> | Iterate dynamic networks</b><i> (1:1, recurring)</i>
2018-10-01  16:45 - 17:00<b> | Deploy robust content</b><i> (recurring)</i>
2018-10-01  17:00 - 17:30<b> | Synthesize viral methodologies</b><i> (recurring)</i>
2018-10-01  17:30 - 17:55<b> | Scale collaborative methodologies</b><i> (1:1, recurring)</i>
2018-10-01  19:00 - 19:30<b> | Recontextualize collaborative content</b><i> (awaiting)</i>
</pre>


### `lint`: Calendar events that require action

<pre>
Usage:
  calendar-assistant lint [DATE | DATERANGE | TIMERANGE]

Options:
  -p, [--profile=PROFILE]                                     # the profile you'd like to use (if different from default)
  -l, [--local-store=FILENAME]                                # Load events from a local file instead of Google Calendar
  -a, --attendees, [--calendars=CALENDAR1[,CALENDAR2[,...]]]  # [default 'me'] people (email IDs) to whom this command will be applied
  -b, [--must-be=PROPERTY1[,PROPERTY2[,...]]]                 # Event properties that must be true (see README)
  -n, [--must-not-be=PROPERTY1[,PROPERTY2[,...]]]             # Event properties that must be false (see README)
  -h, -?, [--help], [--no-help]                               
          [--debug], [--no-debug]                             # how dare you suggest there are bugs
  -f, [--formatting], [--no-formatting]                       # Enable Text Formatting
                                                              # Default: true

Lint your events for a date or range of dates (default 'today')
</pre>

For example: display all events that require action scheduled for tomorrow:

<pre>
<b>$</b> calendar-assistant lint 2018-10-01
me@example.com
- looking for events that need attention
- all times in America/New_York

2018-10-01  11:50 - 12:00<b> | Synergize e-business systems</b><i> (awaiting)</i>
                                    attendees: 👍 three@example.com, 🤷 four@example.com
2018-10-01  12:30 - 13:30<b> | Iterate innovative networks</b><i> (awaiting, recurring)</i>
                                    attendees: 👍 three@example.com, 🤷 four@example.com
2018-10-01  19:00 - 19:30<b> | Recontextualize collaborative content</b><i> (awaiting)</i>
                                    attendees: 👍 three@example.com, 🤷 four@example.com
</pre>


### `config`: View your configuration parameters

Calendar Assistant has intelligent defaults, which can be overridden in the TOML file `~/.calendar-assistant`, and further overridden via command-line parameters. Sometimes it's nice to be able to see what defaults Calendar Assistant is using:

<pre>
Usage:
  calendar-assistant config

Options:
  -h, -?, [--help], [--no-help]          
          [--debug], [--no-debug]        # how dare you suggest there are bugs
  -f, [--formatting], [--no-formatting]  # Enable Text Formatting
                                         # Default: true

Dump your configuration parameters (merge of defaults and overrides from /home/user/.calendar-assistant)
</pre>

The output is TOML, which is suitable for dumping into `~/.calendar-assistant` and editing.

<pre>
<b>$</b> calendar-assistant config
[settings]
end-of-day = "6pm"
location-icon = "🌎"
meeting-length = "30m"
start-of-day = "9am"
</pre>

### `interactive`: Interactive Console

<pre>
Usage:
  calendar-assistant interactive

Options:
  -h, -?, [--help], [--no-help]          
          [--debug], [--no-debug]        # how dare you suggest there are bugs
  -f, [--formatting], [--no-formatting]  # Enable Text Formatting
                                         # Default: true

interactive console for calendar assistant
</pre>

For example, check the version of calendar assistant

```
calendar-assistant> version
0.0.0
```

## Development

### Running Tests Locally

```bash
gem install bundler
bundle install

bundle exec rake spec     # Run all tests except feature tests
bundle exec rake features # Run only feature tests
bundle exec rake          # Default task runs both feature and non feature tests
```

**Note:** Feature tests are excluded by default in [.rspec](.rspec)


### Continuous Integration

CI is running in [Github Actions](https://github.com/flavorjones/calendar-assistant/actions/workflows/test-suite.yml).


### Code Quality

We're running [Code Climate](https://codeclimate.com/github/flavorjones/calendar-assistant) to monitor code quality and test coverage.


### Generate README

* Note that doing this requires npm to be installed
* Generation will use a fixture file rather than connecting to a remote calendar. Fixtures can be updated/regenerated in [generate-fixtures](generate-fixtures) script

```bash
./generate-readme
```


## References

Google Calendar Concepts: https://developers.google.com/calendar/concepts/

Google Calendar API Reference: https://developers.google.com/calendar/v3/reference/

Google Calendar Ruby Client Docs: https://www.rubydoc.info/github/google/google-api-ruby-client/Google/Apis/CalendarV3


## License

See files `LICENSE` and `NOTICE` in this repository.
