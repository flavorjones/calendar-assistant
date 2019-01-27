# Changelog for Calendar Assistant

## unreleased

Features:

- Allow location event visibility to be set. [#17]
- Allow command-specific settings. [#17]
- Support a `nickname` setting and use it in `location-set` to uniquely identify you in an event summmary. [#85]

Breaking Changes:

- Remove support for multiple location icons

## v0.7.0 / 2019-01-15

Features:

- Emit a human-readable error if a calendar ID isn't found. [#58]
- Add `--[no-]formatting` option to all commands.
- Allow home directory to be overridden with `CA_HOME` env var.
- Event attributes only displayed for non-private events.
- Allow additional emoji icons for location events. [#56]


Bugfixes:

- Fix profile authorization. [#67]


## v0.6.0 / 2019-01-01

Features:

- "show": highlights events which have been declined by everybody but you ("abandoned")


## v0.5.0 / 2018-12-10

Features:

- Chronic parse errors are now more user-friendly.
- "availability": All-day events that show time as "busy" will be considered "unavailable time". [#54]


## v0.4.0 / 2018-11-30

Features:

- `show` displays when a meeting has been responded to with "tentative" (a.k.a. "maybe" in the web UI)

Bugfixes:

- `availability` against multiple calendars may have returned blocks shorter than the minimum requested length [#55]


## v0.3.0 / 2018-11-29

Features:

- `availability` shows the intersection of available time for multiple calendars. [#46]
- `version` command will output the version of calendar-assistant
- can read events from a local file [#33]
- much improved README

Bugfixes:

- `availability`: Better handling of edge cases (events at start and end of day, multiple-all-day events, etc.)


## v0.2.1 / 2018-10-31

Features:

- add `setup` command to help set up API client and credentials. [#29]
- ensure config files are chmodded to `600` [#29]
- `show` displays explicit public/private status of an event [#11]

Bug Fixes:

- better handling of joining a zoom when description is nil [#32]


## v0.1.0 / 2018-10-25

First release.
