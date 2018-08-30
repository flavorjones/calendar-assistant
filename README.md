# calendar assistant

A project to help me book (and re-book) one-on-ones and other meetings automatically.


## Features

All datespecs and datetimespecs are interpreted by [Chronic](https://github.com/mojombo/chronic) and so can be fuzzy terms like "tomorrow", "tuesday", "next thursday", and "two days from now" as well as specific dates and times. For a date range or a datetime range, split the start and end with `...` like "tomorrow ... three days from now" or "2018-09-24...2018-09-27".


### Tell people where you are at in the world

Declare your location as an all-day non-busy event:

``` bash
calendar-assistant location set <calendar-id> <datespec> <location-name>
```

Some examples:

``` bash
# create an event titled `🗺 WFH` tomorrow
calendar-assistant location set me@example.com tomorrow WFH

# create an event titled `🗺 OOO` on New Year's Day
calendar-assistant location set me@example.com 2019-01-01 OOO

# create an event titled `🗺 Spring One` on the days of the conference
calendar-assistant location set me@example.com "2018-09-24...2018-09-27" "Spring One"

# create a vacation event for next week
calendar-assistant location set me@example.com "next monday ... next week friday" "Vacation!"
```

### Look up where you're going to be

``` bash
calendar-assistant location get <calendar-id> <datespec>
```

Some examples:

``` bash
calendar-assistant location get me@example.com tomorrow
# => 2018-08-29 Wed          |                         | 🗺  WFH

calendar-assistant location get me@example.com "next week"
# => 2018-08-03 Mon          |                         | 🗺  WFH
     2018-09-04 Tue          | 2018-09-07 Fri          | 🗺  Vacation!
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

Northworld's `google_calendar` gem: https://github.com/northworld/google_calendar


## Usage

Generate a GCal OAuth client id and secret. See Northworld's google_calendar gem README for the steps. The file should be named `client_id.json`.

In GCal, go to your calendar's Settings and grab the "Secret address in iCal format". Pass that to the authorize script.

The refresh token will be written to `calendar_tokens.yml`, which you should be careful not to share or make public.
