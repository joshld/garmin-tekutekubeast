# v0.4 store assets

## Upload assets

- [cover-500.png](cover-500.png): replacement Cover Image, 500 x 500, 131,259 bytes.
  Four-family promotional pixel art; not a screenshot. PNG is below 300 KB.
- [description.txt](description.txt): plain-text Description, below 4,000 characters.
- [whats-new.txt](whats-new.txt): plain-text What's New, below 4,000 characters.
- [pet-simulator.jpg](pet-simulator.jpg) and [glance-simulator.jpg](glance-simulator.jpg):
  genuine v0.4 Enduro 4 simulator captures, not physical-watch photos. They still
  contain the SDK window/watch frame; polished cropped screenshots are not yet
  included. Both JPEGs are below 150 KB. Their extensions match the captured
  format; the earlier local output copies had misleading .png filenames.

Retained [cover-original.png](cover-original.png) is the high-resolution generated
master, not the store upload. [cover-prompt.md](cover-prompt.md) records the
built-in image-generation prompt and the four sprite-atlas reference roles.
The original and 500px export were visually inspected. Store artwork is not
packaged as a runtime watch resource and does not require rebuilding v0.4.0.

## Submission and testing scope

Update the existing beta listing as version 0.4.0; do not create a second app or
uninstall the watch app. This commit does not upload or submit anything to Garmin.
The user reported a server-communication error followed by a dashboard showing
0.4.0; saved store metadata and artwork have not been independently verified.

The user confirmed visible Developer Mode and Glance availability on their
physical Enduro 4. Full hardware acceptance is not complete; see
[the exact evidence and remaining checks](../../../docs/WATCH_ACCEPTANCE.md).

The plain-text store copy retains cautious beta wording about unverified Glance
behaviour, save migration, sounds, vibration and battery use. Glance availability
alone does not establish those checks passed.
