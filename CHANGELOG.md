# Changelog for Calendar Assistant

## v0.16.0 / 2024-07-27

Fixes:

- updated to support Ruby 3.2+ [#195] @paracycle


## v0.15.0 / 2021-05-01

Fixes:

- support profile names that are email addresses [#188]


Dependencies:

- move to `toml-rb` to support non-bare TOML keys


## v0.14.0 / 2021-02-24

Dependencies:

- Move from google-api-client to google-apis-calendar_v3
- activesupport ~> 6.1
- business_time ~> 0.10
- thor ~> 1.1.0


## v0.13.0 / 2020-05-09

Features:

- Avoid Ruby 2.7 deprecation warnings. [#159]


## v0.12.0 / 2020-04-09

Features:

- Support password parameters for Zoom conferences. Survive the pandemic in security and style. [#154]


## v0.11.0 / 2019-03-24

Features:

- Emit human-readable message upon TOML parsing failures. [#92]
- `join` detects zoom links in conference metadata. [#119]


Bug fixes:

- Update thor_repl dependency so `interactive` will handle embedded whitespace. [#128]



## v0.10.0 / 2019-02-26

Features:

- Interactive console mode: `interactive`


## v0.9.0 / 2019-02-11

Features:

- Support multiple calendars `--calendars` to manage location events on multiple calendars. [#63]
- Emit human-readable error message when location config is invalid. [#95]
- Zoom meetings will be launched with the `zoom` cli instead of the browser. [#91]


## v0.8.0 / 2019-01-28

Features:

- Most commands now allow filtering by property. See README for details on `--must-be` and `--must-not-be`. [#72]
- Allow location event visibility to be set. [#17]
- Allow command-specific settings. [#17]
- Support a `nickname` setting and use it in `location-set` to uniquely identify you in an event summmary. [#85]


Breaking Changes:

- Remove support for multiple location event icons.


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
