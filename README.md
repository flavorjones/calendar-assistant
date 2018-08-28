# calendar assistant

A project to help me book (and re-book) one-on-ones and other meetings automatically.


## Features

All datespecs and datetimespecs are interpreted by [Chronic](https://github.com/mojombo/chronic) and so can be fuzzy terms like "tomorrow", "tuesday", "next thursday", and "two days from now" as well as specific dates and times. For a date range or a datetime range, split the start and end with `...`.


### Tell people where you are at in the world

Declare your geographic location as an all-day non-busy event:

``` bash
calendar-assistant where <datespec> <location-name> -c <google-calendar-id>
```

Some examples:

``` bash
calendar-assistant where tomorrow WFH -c me@example.com # creates an event titled `🗺 WFH` tomorrow
calendar-assistant where 2019-01-01 OOO -c me@example.com # creates an event titled `🗺 OOO` on New Year's Day
calendar-assistant where "2018-09-24 ... 2018-09-27 "Spring One" -c me@example.com # creates an event titled `🗺 Spring One` on the days of the conference
```


### Future

Practing Readme-Driven-Development (RDD), some features I'd like to build are:

- create all-day (non-busy) events indicating where in the world I am
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
