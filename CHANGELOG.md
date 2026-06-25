# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.0.0]

Initial release.

### Added
- Lock the Dock to a chosen display via a `CGEventTap` cursor barrier, without disabling
  *Displays Have Separate Spaces*.
- Menu-bar UI: enable/disable, pick the locked display, Launch at Login, quit.
- Automatic Dock-edge detection (bottom/left/right).
- Display selection persisted by UUID with fallback to the main display.
- First-launch Accessibility prompt and Launch-at-Login enabled by default.
- App icon and a build script that produces a code-signed `.app` bundle.
- `scripts/setup-signing.sh` for a stable self-signed identity so the Accessibility grant
  survives rebuilds.
