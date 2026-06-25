# Contributing to DockAnchor

Thanks for your interest in improving DockAnchor! It's a small, focused utility, so
contributions are easy to review when they stay tight in scope.

## Getting started

1. Fork and clone the repo.
2. Build: `swift build` (or `bash scripts/build-app.sh` for a runnable `.app`).
3. For an end-to-end run, see the build/install steps in the [README](README.md).

## Guidelines

- **Keep the scope tight.** DockAnchor does one thing — lock the Dock to a display. New
  options should earn their place; prefer sensible defaults over more toggles.
- **Match the existing style.** Plain AppKit, no third-party dependencies, small focused
  types. Run a clean build and make sure there are no new warnings:
  `swift build -c release`.
- **Explain the "why."** Event-tap and coordinate-space code is subtle; comment the
  reasoning, not just the mechanics.

## Testing changes

DockAnchor's behavior depends on real hardware (multiple displays, Accessibility
permission), which is hard to unit-test. When you change the guard or display logic, please
verify manually and note what you tested in your PR:

- With ≥2 displays and the Dock set to auto-hide, confirm the Dock stays on the selected
  display and does not appear when you push the cursor to the bottom of the others.
- Switch the locked display via **Lock Dock to ▸** and re-test.
- Toggle **Enabled** off and confirm the Dock jumps freely again.
- Disconnect/reconnect the selected display and confirm graceful fallback.

## Submitting

Open a pull request with a clear description of the change and the manual testing you did.
Small, single-purpose PRs are merged fastest.

By contributing, you agree that your contributions are licensed under the project's
[MIT License](LICENSE).
