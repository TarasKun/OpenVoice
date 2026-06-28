# Decisions

## Recording Target Is Decided At Recording Start

Decision: recording target must be decided when recording starts, not when recording stops.

Reason: the stop action can come from different UI controls or from smart stop. Therefore all stop paths must use the same recording session target.

Implications:

- Global Start Recording sets target to `new note`.
- Note-level Record sets target to `existing note(id)`.
- Global Stop Recording must not overwrite the target.
- Note-level Stop Recording must not overwrite the target.
- Smart stop must use the target from the current recording session.
- Transcription save behavior must be based on the recording session target.

