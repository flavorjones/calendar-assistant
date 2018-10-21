
# calendar assistant

A command-line tool to help me manage my Google Calendar.

- book (and re-book) one-on-ones and other meetings automatically
- set up all-day events to let people know your location in the world
- easily join the videoconference for your current meeting

[![Concourse CI](https://ci.nokogiri.org/api/v1/teams/calendar-assistants/pipelines/calendar-assistant/jobs/rake-spec/badge)](https://ci.nokogiri.org/teams/calendar-assistants/pipelines/calendar-assistant)

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


### Preferences

All tokens and preferences will be stored in `~/.calendar-assistant` which is in TOML format.


### Commands

#### Authorize access to your Google Calendar

<pre>
<b>$</b> calendar-assistant help authorize
Usage:
  calendar-assistant authorize PROFILE_NAME

Options:
  -p, [--profile=PROFILE]      # the profile you'd like to use (if different from default)
  -d, [--debug], [--no-debug]  # how dare you suggest there are bugs

Description:
  Create and authorize a named profile (e.g., "work", "home", "flastname@company.tld") to access your calendar.

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


#### Display your calendar events

<pre>
<b>$</b> calendar-assistant help show
Usage:
  calendar-assistant show [DATE | DATERANGE | TIMERANGE]

Options:
  -c, [--commitments], [--no-commitments]  # only show events that you've accepted with another person
  -p, [--profile=PROFILE]                  # the profile you'd like to use (if different from default)
  -d, [--debug], [--no-debug]              # how dare you suggest there are bugs

Show your events for a date or range of dates (default 'today')

</pre>

For example: display all events scheduled for tomorrow:

<pre>
<b>$</b> calendar-assistant show --profile=work 2018-10-01
2018-10-01               <b> | 🗺  NJ</b><i> (not-busy, self)</i>
<strike>2018-10-01  03:30 - 05:00 | INTERNATIONAL COFFEE DAYYYYYYYY</strike>
<strike>2018-10-01  07:30 - 08:30 | Lunch and  -GDPR</strike>
<strike>2018-10-01  07:30 - 08:30 | Lunch & Learn</strike>
2018-10-01  08:00 - 09:00<b> | Commuting/Email</b><i> (recurring, self)</i>
2018-10-01  09:00 - 10:30<b> | None</b><i> (self)</i>
2018-10-01  10:30 - 10:55<b> | Mike D / Stev 1:1</b><i> (1:1, recurring)</i>
2018-10-01  11:00 - 11:30<b> | Dublin Office Status Meeting</b><i> (recurring)</i>
2018-10-01  11:30 - 12:00<b> | Mike/Rupa 1:1</b><i> (1:1, recurring)</i>
<strike>2018-10-01  11:50 - 12:00 | Reminder: CF Standup prep (recurring)</strike>
2018-10-01  12:00 - 12:30<b> | Lunch</b><i> (self)</i>
<strike>2018-10-01  12:15 - 12:30 | CF NYC Standup (recurring)</strike>
<strike>2018-10-01  12:30 - 13:30 | Office Events Retro</strike>
2018-10-01  12:30 - 13:30<b> | Global Director's Check-In</b><i> (recurring)</i>
2018-10-01  13:30 - 14:50<b> | proactivity</b><i> (self)</i>
<strike>2018-10-01  13:30 - 14:30 | Psychological Safety Workshop (Session 1)</strike>
2018-10-01  15:00 - 15:30<b> | Matthew/Mike</b><i> (1:1)</i>
2018-10-01  16:00 - 17:00<b> | Mike/Ryan T. 1:1</b><i> (1:1, recurring)</i>
2018-10-01  16:45 - 17:00<b> | Manager Initiative check-in</b><i> (recurring)</i>
2018-10-01  17:00 - 17:30<b> | CF Security Council Sync</b><i> (recurring)</i>
2018-10-01  17:30 - 17:55<b> | Mike / Dieu 1:1</b><i> (1:1, recurring)</i>
<strike>2018-10-01  18:00 - 20:30 | Steak!</strike>
<strike>2018-10-01  18:30 - 19:00 | SF CF Directors / HR Bi-weekly (recurring)</strike>
<strike>2018-10-01  19:00 - 19:30 | CF SF Manager Sit Down (recurring)</strike>

</pre>

Display _only_ the commitments I have to other people using the `-c` option:

<pre>
<b>$</b> calendar-assistant show -c 2018-10-01
2018-10-01  10:30 - 10:55<b> | Mike D / Stev 1:1</b><i> (1:1, recurring)</i>
2018-10-01  11:00 - 11:30<b> | Dublin Office Status Meeting</b><i> (recurring)</i>
2018-10-01  11:30 - 12:00<b> | Mike/Rupa 1:1</b><i> (1:1, recurring)</i>
2018-10-01  12:30 - 13:30<b> | Global Director's Check-In</b><i> (recurring)</i>
2018-10-01  15:00 - 15:30<b> | Matthew/Mike</b><i> (1:1)</i>
2018-10-01  16:00 - 17:00<b> | Mike/Ryan T. 1:1</b><i> (1:1, recurring)</i>
2018-10-01  16:45 - 17:00<b> | Manager Initiative check-in</b><i> (recurring)</i>
2018-10-01  17:00 - 17:30<b> | CF Security Council Sync</b><i> (recurring)</i>
2018-10-01  17:30 - 17:55<b> | Mike / Dieu 1:1</b><i> (1:1, recurring)</i>

</pre>


#### Tell people where you are at in the world

Declare your location as an all-day non-busy event:

<pre>
<b>$</b> calendar-assistant help location-set
Usage:
  calendar-assistant location-set LOCATION [DATE | DATERANGE]

Options:
  -p, [--profile=PROFILE]      # the profile you'd like to use (if different from default)
  -d, [--debug], [--no-debug]  # how dare you suggest there are bugs

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

#### Look up where you're going to be

<pre>
<b>$</b> calendar-assistant help location
Usage:
  calendar-assistant location [DATE | DATERANGE]

Options:
  -p, [--profile=PROFILE]      # the profile you'd like to use (if different from default)
  -d, [--debug], [--no-debug]  # how dare you suggest there are bugs

Show your location for a date or range of dates (default 'today')

</pre>

For example:

<pre>
<b>$</b> calendar-assistant location "2018-09-24...2018-09-28"
2018-09-24 - 2018-09-27  <b> | 🗺  Spring One @ DC</b><i> (not-busy, self)</i>
2018-09-28               <b> | 🗺  NJ</b><i> (not-busy, self)</i>

</pre>

#### Join a video call attached to a meeting

<pre>
<b>$</b> calendar-assistant help join
Usage:
  calendar-assistant join [TIME]

Options:
      [--join], [--no-join]    # launch a browser to join the video call URL
                               # Default: true
  -p, [--profile=PROFILE]      # the profile you'd like to use (if different from default)
  -d, [--debug], [--no-debug]  # how dare you suggest there are bugs

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


## References

Google Calendar Concepts: https://developers.google.com/calendar/concepts/

Google's API docs: https://www.rubydoc.info/github/google/google-api-ruby-client/Google/Apis/CalendarV3

Recurrence: https://github.com/seejohnrun/ice_cube


## License

See files `LICENSE` and `NOTICE` in this repository.
