# Open Voice – Product Behavior Specification

## 1. Purpose

Open Voice is a small desktop/widget-style transcription app. The main workflow is simple:

1. User records voice.
2. App transcribes it into a note.
3. User can edit, copy, append to, or delete notes.
4. Model management is hidden inside Settings.

The main UI should stay focused on transcription history and recording.

---

## 2. Main Layout

### Header

- App title: **Open Voice**.
- Settings icon: gear icon in the top-right corner.
- Model selection controls should not be shown in the main screen.
- Model controls are available only inside Settings.

### Notes area

- Transcription history occupies the main page area.
- Notes are displayed like a chat:
  - Older notes at the top.
  - Newer notes at the bottom.
- On app/widget launch, the notes list should automatically scroll to the bottom so the newest notes are visible.
- The last note must never be hidden behind the bottom controls/status area.
- The scroll container must reserve enough bottom space so the final note can be fully scrolled into view.
- Avoid excessive empty space between the last note and the bottom controls.
- Recommended bottom gap between the last note and bottom controls: around **12–16 px**.

### Bottom area

The bottom area contains:

- Optional status message, for example copy confirmation.
- Decibel/microphone level indicator.
- Large **Start Recording / Stop Recording** button.

The bottom controls should feel visually connected to the notes list and should not create a large unnecessary blank gap.

---

## 3. Recording Behavior

### Main bottom recording button

The large bottom **Start Recording / Stop Recording** button always creates a **new note**.

Expected behavior:

- Press **Start Recording** from the bottom button.
- Press **Stop Recording**.
- App creates a new note with the transcribed text.
- It must not append to the previous note.

### Note-level recording button

Each note has a small action icon for continuing transcription into that specific note.

Expected behavior:

- User clicks the small continue/transcribe icon inside a note.
- App records audio.
- After transcription, the new text is appended to that same note.
- It must not create a new note.
- It must append only to the note where the user clicked the icon.

### Recording vs transcription state

When transcription is processing:

- The recording button is disabled.
- The Start/Stop icon inside the button is replaced by a spinner.
- Spinner should look smooth and Apple-like.
- The button remains disabled until transcription finishes.
- After transcription completes, restore the normal Start/Stop icon.

---

## 4. Notes Behavior

### Editable notes

- Each transcribed note should be editable after creation.
- User edits should be saved automatically.
- Pressing **Enter** inside a note should insert a new line.
- Pressing **Enter** must not select all text inside the note.

### Note height

- Notes should not have a fixed default height.
- A note should naturally adapt to its text content.
- If a note has only one line, timestamp and text should align to the top, not vertically center.
- Each note must have a minimum height equal to at least the height required by the action icon block.

### Note padding

- Add comfortable inner padding inside each note.
- Text should not be too close to the container edges.
- Text should not sit too close to the bottom border.

### Long notes

For long notes:

- The user should be able to scroll through the note content if needed.
- While typing long text, the scroll position should automatically follow the cursor.
- The newly typed text must always remain visible.
- The user should never type “behind the screen” or outside the visible area.

---

## 5. Note Action Icons

Each note should have an action icon block containing:

- Delete icon / X.
- Continue transcription into this note icon.
- Copy icon.

### Icon positioning

- The icon block must be pinned to the top-right corner of the note.
- For long notes, when the user scrolls down inside the note, the icon block should stay visible.
- The icons must always remain accessible without scrolling back to the top or bottom.
- This should behave like a fixed/sticky action block inside the note.

### Remove scroll artifact

- Remove the strange white scroll-like artifact that appears near each saved note.
- Notes should not show an unnecessary automatic scrollbar/scroll indicator unless actual scrolling is needed.

---

## 6. Copy Behavior

### Basic copy

- Each note has a Copy icon on the right side.
- Clicking it copies the note text to the clipboard.
- The copied text can be pasted anywhere.

### Copy full note content

If a note contains multiple transcription blocks or paragraphs, the Copy button must copy the **entire note**, not only the first block.

Example:

```text
First transcribed paragraph.

Second appended paragraph.
```

Expected copied result:

```text
First transcribed paragraph.

Second appended paragraph.
```

### Copy feedback

After clicking Copy:

- Show a clear confirmation that copying worked.
- Use a visible animation or state change.
- Possible options:
  - temporary checkmark,
  - short highlight,
  - “Copied” message,
  - icon bounce/fade animation.

The feedback should be more obvious than a barely visible status message.

---

## 7. Delete Behavior

Each note has a delete X icon.

Expected behavior:

1. User clicks X.
2. Show confirmation dialog:

   **“Are you sure you want to delete this note?”**

3. Delete the note only after confirmation.
4. Cancel keeps the note unchanged.

---

## 8. Decibel / Microphone Level Indicator

- The decibel scale should be hidden or visually minimized when recording is inactive.
- The layout must not jump when the decibel indicator appears or disappears.
- Reserve the same layout space or use a stable container so UI does not shift.

---

## 9. Empty Model State

When no models are downloaded:

- Hide the large bottom **Start Recording** button.
- Show grey helper text instead:

  **“No models available. Go to Settings to download a model.”**

- No model should have an active border.
- User should not be able to change the active model.

When exactly one model is downloaded:

- It should automatically become the active model.
- Other models that are not downloaded should not be selectable.

When multiple models are downloaded:

- User can select one active model.
- Active model should persist between app/widget restarts.

---

## 10. Settings Window

### General

- Settings opens from the gear icon.
- Settings title should be:

  **Models**

### Model list

- Do not use a dropdown for the active model.
- Show models as selectable cards/items.
- The active downloaded model is highlighted with a border.
- If no models are downloaded, no active border is shown.
- If only one model is downloaded, it is automatically highlighted.
- Models that are not downloaded should not be selectable as active models.

### Model metadata

Each model description should show both:

- **Model size on disk** — how much storage the model file occupies.
- **Estimated VRAM usage** — approximate video memory required while the model runs.

Example:

```text
Size: 1.5 GB
VRAM: ~2.5 GB
```

Do not show only VRAM usage.

### Persist active model

The app must remember the previously selected model between restarts.

Expected behavior:

- User selects the medium model.
- User reloads or restarts the widget/app.
- The medium model remains selected.
- App must not reset back to the base model.

Persistence rules:

- Store selected model ID in local app settings/storage.
- On launch, restore the selected model if it is still downloaded and available.
- If the selected model was deleted, fallback to another downloaded model.
- If no models are downloaded, no model is selected.

---

## 11. Model Download Behavior

### Download must work

- Models currently fail to download in some cases.
- The download process must be investigated and fixed.
- User should be able to download models successfully from Settings.

### Progress bar

Current bug:

- Model downloads, but progress bar stays at minimum.

Expected behavior:

- Progress bar updates in real time during model download.
- It reflects the actual downloaded percentage.
- It reaches 100% when complete.
- If download progress cannot be calculated, show an indeterminate loading state instead of a fixed minimum value.

---

## 12. Widget Context Menu

When the user right-clicks the widget, show a context menu with two options:

- **Reload**
- **Quit**

### Reload

- Restarts/reloads the widget without closing the whole application.
- Must preserve user data and selected model.

### Quit

- Fully exits the application.
- After quitting, user can launch the app normally from Applications, Dock, Spotlight, or another configured launcher.

---

## 13. Known Layout Bugs to Avoid

### Last note clipped by bottom area

Bug:

- The last note is partially hidden behind the bottom message/control area.

Fix:

- Scrollable notes area must end above the bottom controls.
- Add enough bottom padding or correctly calculate scroll container height.
- The last note must always be fully visible.

### Too much empty space before bottom controls

Bug:

- Large blank space appears between the final note and bottom controls.

Fix:

- Reduce unnecessary vertical gap.
- Keep spacing compact and consistent.

### Short note content centered vertically

Bug:

- If note has one line, timestamp and text appear vertically centered.

Fix:

- Align timestamp and text to the top edge like all other notes.

---

## 14. Expected UX Summary

The app should feel like a compact transcription chat:

- Notes appear chronologically, newest at the bottom.
- Main recording button creates new notes.
- Note-level recording button appends to existing notes.
- Notes are editable and auto-saved.
- Copy always copies the full note.
- Action icons are always visible.
- Models are managed quietly inside Settings.
- Empty model state clearly tells the user what to do.
- Layout should never jump, clip content, or waste large vertical space.
