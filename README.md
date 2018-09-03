# calendar assistant

A project to help me book (and re-book) one-on-ones and other meetings automatically.


## Features

All datespecs and datetimespecs are interpreted by [Chronic](https://github.com/mojombo/chronic) and so can be fuzzy terms like "tomorrow", "tuesday", "next thursday", and "two days from now" as well as specific dates and times. For a date range or a datetime range, split the start and end with `...` like "tomorrow ... three days from now" or "2018-09-24...2018-09-27".

Events are nicely formatted, with strikeouts for events you've declined, and some additional attributes listed when present (e.g., "needsAction", "self", "not-busy", ....)


### Display your calendar events

``` bash
calendar-assistant show <calendar-id> [<datespec>]
```

For example:

``` bash
# show me my day
$ calendar-assistant show me@example.com

2019-11-01  08:00 - 09:00 | Commuting/Email (self)
2019-11-01  11:00 - 12:00 | Jimbo/Mike 1:1
2019-11-01  11:00 - 11:00 | CF NYC Planning: Allocations & Interviews
2019-11-01  11:00 - 11:00 | Security KPL Checkin
2019-11-01  12:00 - 13:00 | VP Weekly Sync
2019-11-01  12:00 - 13:00 | Consulting Lunch (needsAction)
2019-11-01  13:00 - 14:00 | R&D Key Priorities Check-In (needsAction)
2019-11-01  14:00 - 15:00 | Mike/Jones 1:1
2019-11-01  15:00 - 15:00 | SF Office Status Meeting (declined)
2019-11-01  16:00 - 17:00 | Mike/Jane 1:1
2019-11-01  16:00 - 17:00 | Mike/Julie T. 1:1
2019-11-01  18:00 - 19:00 | OOO  (self)

(All times are in America/New_York)

# show me my day, with recurrence information for each event
$ calendar-assistant show me@example.com tuesday -v

2019-11-01  08:00 - 09:00 | Commuting/Email (self) [Weekly on Weekdays]
2019-11-01  11:00 - 12:00 | Jimbo/Mike 1:1 [Every 2 weeks on Fridays]
2019-11-01  11:00 - 11:00 | CF NYC Planning: Allocations & Interviews [Weekly on Fridays]
2019-11-01  11:00 - 11:00 | Security KPL Checkin [Weekly on Fridays]
2019-11-01  12:00 - 13:00 | VP Weekly Sync [Weekly on Fridays]
2019-11-01  12:00 - 13:00 | Consulting Lunch (needsAction) [Monthly on the 1st Friday]
2019-11-01  13:00 - 14:00 | R&D Key Priorities Check-In (needsAction) [Every 2 weeks on Fridays]
2019-11-01  14:00 - 15:00 | Mike/Jones 1:1 [Every 2 weeks on Fridays]
2019-11-01  15:00 - 15:00 | SF Office Status Meeting (declined) [Every 2 weeks on Fridays]
2019-11-01  16:00 - 17:00 | Mike/Jane 1:1 [Every 3 weeks on Fridays]
2019-11-01  16:00 - 17:00 | Mike/Julie T. 1:1 [Every 2 weeks on Fridays]
2019-11-01  18:00 - 19:00 | OOO  (self) [Weekly on Weekdays]
```

### Tell people where you are at in the world

Declare your location as an all-day non-busy event:

``` bash
calendar-assistant location set <calendar-id> <datespec> <location-name>
```

Some examples:

``` bash
# create an event titled `🗺 WFH` tomorrow
$ calendar-assistant location set me@example.com tomorrow WFH

# create an event titled `🗺 OOO` on New Year's Day
$ calendar-assistant location set me@example.com 2019-01-01 OOO

# create an event titled `🗺 Spring One` on the days of that conference
$ calendar-assistant location set me@example.com "2018-09-24...2018-09-27" "Spring One"

# create a vacation event for next week
$ calendar-assistant location set me@example.com "next monday ... next week friday" "Vacation!"
```

### Look up where you're going to be

``` bash
calendar-assistant location get <calendar-id> [<datespec>]
```

For example:

``` bash
$ calendar-assistant location get me@example.com "today...next month"

(All times are in America/New_York)
2018-09-04 - 2018-09-08 | 🗺  NYC (not-busy, self)
2018-09-24 - 2018-09-28 | 🗺  Spring One @DC (not-busy, self)
2018-09-28 - 2018-09-29 | 🗺  WFH (not-busy, self)
```

### Future

Practing Readme-Driven-Development (RDD), some features I'd like to build are:

- create variations on 1:1s
  - every N weeks for 30 minutes
  - every N weeks alternating 30 and 60 minutes
  - alternating 2:1 with 1:1s between two people
  - preference for start-of-day (breakfast) or end-of-day (pub)
  - one-time 1:1 within a time period
  - pool of people with repeating time slot (e.g. all CF Eng managers)
- block off time when a day approaches full
  - optimize for big blocks of time
- mirror any flights I have from my Tripit calendar to my primary calendar
  - with 90 minute blocks before and after for travel to the airport, etc.

Also, I need to make this a real Ruby Gem so people can install it. :-\


## References

Google Calendar Concepts: https://developers.google.com/calendar/concepts/

Google's API docs: https://www.rubydoc.info/github/google/google-api-ruby-client/Google/Apis/CalendarV3

Recurrence: https://github.com/seejohnrun/ice_cube


## Usage

Generate a GCal OAuth client id and secret. See Northworld's google_calendar gem README for the steps. The file should be named `client_id.json`.

In GCal, go to your calendar's Settings and grab the "Secret address in iCal format". Pass that to the authorize script.

The refresh token will be written to `calendar_tokens.yml`, which you should be careful not to share or make public.


## License

See files `LICENSE` and `NOTICE` in this repository.
