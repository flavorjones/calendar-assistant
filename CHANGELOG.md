# Changelog for Calendar Assistant

## v0.3.0 / unreleased

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
