# calendar assistant

A command-line tool to help me book (and re-book) one-on-ones and other meetings automatically.


## Usage

Head to https://developers.google.com/calendar/quickstart/ruby to enable the Calendar API for your Google account and create a new "project". Save the project info in `credentials.json`.

Then run `calendar-assistant authorize PROFILE_NAME` (see below for details).


## Features

### Pretty Display

Events are nicely formatted, with faint strikeouts for events you've declined, and some additional attributes listed when present (e.g., "needsAction", "self", "not-busy", "1:1" ...)

Event "recurrence rules" are expressed in plain english like "Every 2 weeks on Tuesdays", thanks to [Ice Cube](https://github.com/seejohnrun/ice_cube).


### Date and Time Specification

All dates and times are interpreted by [Chronic](https://github.com/mojombo/chronic) and so can be fuzzy terms like "tomorrow", "tuesday", "next thursday", and "two days from now" as well as specific dates and times.

For a date range or a datetime range, split the start and end with `..` or `...` like:

* "tomorrow ... three days from now"
* "2018-09-24..2018-09-27".

Also note that every command will adopt an intelligent default, which is generally "today" or "now".


### Commands

#### Authorize access to your Google Calendar

``` bash
calendar-assistant authorize PROFILE_NAME
```

This command will generate a URL which you should load in your browser while logged in as the Google account you wish to authorize. Generate a token, and paste the token back into `calendar-assistant`. The refresh token will be written to `token.yml`, which you should be careful not to share or make public.


#### Display your calendar events

``` bash
calendar-assistant show [-c] PROFILE_NAME [DATE | DATERANGE | TIMERANGE]
```

The `-c` ("--commitments") option will omit events that you haven't accepted (either "yes" or "maybe") and that are with at least one other person.

For example: display all events scheduled for tomorrow:

<pre>
<b>$</b> calendar-assistant show work 2018-10-01
2018-10-01 - 2018-10-05  <b> | Ian Huston @ NYC</b><i> (not-busy, self)</i>
2018-10-01               <b> | 🗺  NYC</b><i> (not-busy, self)</i>
<strike>2018-10-01  03:30 - 05:00 | INTERNATIONAL COFFEE DAYYYYYYYY</strike>
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
<strike>2018-10-01  12:40 - 13:00 | PKS 1.2 Release Check In  (recurring)</strike>
2018-10-01  13:30 - 14:30<b> | Psychological Safety Workshop (Session 1)</b>
2018-10-01  14:30 - 15:30<b> | Break</b><i> (self)</i>
2018-10-01  15:00 - 15:30<b> | Matthew/Mike</b><i> (1:1)</i>
2018-10-01  15:30 - 15:55<b> | Mike D / Aloka: the Donut commands it</b><i> (1:1, recurring)</i>
2018-10-01  16:00 - 17:00<b> | Mike/Ryan T. 1:1</b><i> (1:1, recurring)</i>
2018-10-01  16:45 - 17:00<b> | Manager Initiative check-in</b><i> (recurring)</i>
2018-10-01  17:00 - 17:30<b> | CF Security Council Sync</b><i> (recurring)</i>
2018-10-01  17:30 - 17:55<b> | Mike / Dieu 1:1</b><i> (1:1, recurring)</i>
2018-10-01  18:00 - 20:30<b> | Steak!</b>
<strike>2018-10-01  18:30 - 19:00 | SF CF Directors / HR Bi-weekly (recurring)</strike>
<strike>2018-10-01  19:00 - 19:30 | CF SF Manager Sit Down (recurring)</strike>
</pre>


Display _only_ the commitments I have to other people using the `-c` option:

<pre>
<b>$</b> calendar-assistant show work 2018-10-01 -c
2018-10-01  10:30 - 10:55<b> | Mike D / Stev 1:1</b><i> (1:1, recurring)</i>
2018-10-01  11:00 - 11:30<b> | Dublin Office Status Meeting</b><i> (recurring)</i>
2018-10-01  11:30 - 12:00<b> | Mike/Rupa 1:1</b><i> (1:1, recurring)</i>
2018-10-01  12:30 - 13:30<b> | Global Director's Check-In</b><i> (recurring)</i>
2018-10-01  13:30 - 14:30<b> | Psychological Safety Workshop (Session 1)</b>
2018-10-01  15:00 - 15:30<b> | Matthew/Mike</b><i> (1:1)</i>
2018-10-01  15:30 - 15:55<b> | Mike D / Aloka: the Donut commands it</b><i> (1:1, recurring)</i>
2018-10-01  16:00 - 17:00<b> | Mike/Ryan T. 1:1</b><i> (1:1, recurring)</i>
2018-10-01  16:45 - 17:00<b> | Manager Initiative check-in</b><i> (recurring)</i>
2018-10-01  17:00 - 17:30<b> | CF Security Council Sync</b><i> (recurring)</i>
2018-10-01  17:30 - 17:55<b> | Mike / Dieu 1:1</b><i> (1:1, recurring)</i>
2018-10-01  18:00 - 20:30<b> | Steak!</b>
</pre>


Display additional recurrence information using the `-v` option:

<pre>
<b>$</b> calendar-assistant show work 2018-10-01 -c -v
2018-10-01  10:30 - 10:55<b> | Mike D / Stev 1:1</b><i> (1:1, recurring)</i> [Weekly on Mondays]
2018-10-01  11:00 - 11:30<b> | Dublin Office Status Meeting</b><i> (recurring)</i> [Every 2 weeks on Mondays]
2018-10-01  11:30 - 12:00<b> | Mike/Rupa 1:1</b><i> (1:1, recurring)</i> [Every 3 weeks on Fridays]
2018-10-01  12:30 - 13:30<b> | Global Director's Check-In</b><i> (recurring)</i> [Weekly on Mondays]
2018-10-01  13:30 - 14:30<b> | Psychological Safety Workshop (Session 1)</b>
2018-10-01  15:00 - 15:30<b> | Matthew/Mike</b><i> (1:1)</i>
2018-10-01  15:30 - 15:55<b> | Mike D / Aloka: the Donut commands it</b><i> (1:1, recurring)</i> [Every 3 weeks on Tuesdays]
2018-10-01  16:00 - 17:00<b> | Mike/Ryan T. 1:1</b><i> (1:1, recurring)</i> [Every 2 weeks on Fridays]
2018-10-01  16:45 - 17:00<b> | Manager Initiative check-in</b><i> (recurring)</i> [Weekly on Weekdays]
2018-10-01  17:00 - 17:30<b> | CF Security Council Sync</b><i> (recurring)</i> [Weekly on Mondays]
2018-10-01  17:30 - 17:55<b> | Mike / Dieu 1:1</b><i> (1:1, recurring)</i> [Weekly on Mondays]
2018-10-01  18:00 - 20:30<b> | Steak!</b>
</pre>


#### Tell people where you are at in the world

Declare your location as an all-day non-busy event:

``` bash
calendar-assistant location-set PROFILE_NAME LOCATION [DATE | DATERANGE]
```

**Note** that you can only be in one place at a time, so existing location events may be modified or deleted when new overlapping events are created.

Some examples:

``` bash
# create an event titled `🗺 WFH` for today
$ calendar-assistant location set work WFH
Created:
2018-09-03                | 🗺  WFH (not-busy, self)

# create an event titled `🗺 OOO` for tomorrow
$ calendar-assistant location set work OOO tomorrow
Created:
2018-09-04                | 🗺  OOO (not-busy, self)

# create an event titled `🗺 Spring One` on the days of that conference
$ calendar-assistant location set work "Spring One" 2018-09-24...2018-09-27
Created:
2018-09-24 - 2018-09-27   | 🗺  Spring One (not-busy, self)

# create a vacation event for next week
$ calendar-assistant location set work "Vacation!" "next monday ... next week friday"
Created:
2018-09-10 - 2018-09-14   | 🗺  Vacation! (not-busy, self)
```

#### Look up where you're going to be

``` bash
calendar-assistant location [-v] PROFILE_NAME [DATE | DATERANGE]
```

For example:

``` bash
$ calendar-assistant location show work "today...next month"

2018-09-04 - 2018-09-07 | 🗺  NYC (not-busy, self)
2018-09-24 - 2018-09-27 | 🗺  Spring One @DC (not-busy, self)
2018-09-28              | 🗺  WFH (not-busy, self)
```

#### Join a video call attached to meeting 

``` bash
calendar-assistant join [-p] PROFILE_NAME [TIME]
```

The `-p` ("--print") option will display the video URL instead of joining.

Some examples:

``` bash
$ calendar-assistant join work

[opens URL associated with an event happening now]

$ calendar-assistant join work -p 11:30

2018-09-28  11:30 - 12:00 | Status Meeting (recurring)
https://pivotal.zoom.us/j/ABC90210
```

## References

Google Calendar Concepts: https://developers.google.com/calendar/concepts/

Google's API docs: https://www.rubydoc.info/github/google/google-api-ruby-client/Google/Apis/CalendarV3

Recurrence: https://github.com/seejohnrun/ice_cube


## License

See files `LICENSE` and `NOTICE` in this repository.
