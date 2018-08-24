# TODO

## Experiments

- [x] how do I authenticate without writing creds to disk
- [x] can I determine people's native timezones
- [-] can I resolve email address to a person's name
- [x] can I see other people's busy/free status


## Notes

If an event is only visible via free/busy status, it will be `visibility: private` and the person is assumed to be busy

If an event is only for the person, attendees will be nil and the person is assumed to be busy.

If there are attendees, then the person's response will be one of:
- accepted, and the person is assumed to be busy
- needsAction or tentative, and the person might be busy
- declined, and the person is assumed to be not attending that meeting

