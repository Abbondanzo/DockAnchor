# DockAnchor

**Lock the macOS Dock to one display.**

![platform](https://img.shields.io/badge/platform-macOS%2013%2B-blue)
![swift](https://img.shields.io/badge/swift-5.9%2B-orange)
![license](https://img.shields.io/badge/license-MIT-green)

On a multi-monitor Mac with the Dock set to auto-hide, macOS slides the Dock onto
whichever screen you push the cursor against at the bottom edge. DockAnchor stops that:
the Dock stays on the display you choose, without turning off *Displays Have Separate
Spaces* (which forces a logout and removes per-display menu bars and spaces).

It's a tiny menu-bar app, no Dock icon, that does exactly one thing.

## Features

- Pin the Dock to a display of your choice; it never jumps to the others.
- Works with bottom, left, or right Docks; the edge is detected automatically.
- Remembers your chosen display by UUID, so it survives reconnects (falls back to the
  main display if that display is gone).
- Optional Launch at Login (on by default after first run).
- Minimal: a single status-bar item, no windows, no background polling of the Dock.

## How it works

The Dock's auto-show is decided by the WindowServer purely from the cursor's global
position, so a transparent overlay window can't intercept it. Instead, DockAnchor installs
a [`CGEventTap`](https://developer.apple.com/documentation/coregraphics/cgevent/) that
watches mouse-move/drag events and, when the cursor enters the bottom ~2px of a
non-selected display, nudges it back up a pixel. This builds an invisible floor so the
bottom-edge hit region of the other displays can never be reached, while the selected
display's edge is left untouched so the Dock works normally there.

Because the tap modifies events, it needs Accessibility permission.

## Installation

Requires macOS 13+ and a Swift 5.9+ toolchain (Xcode or the Swift toolchain).

```sh
git clone <your-fork-url> DockAnchor && cd DockAnchor && bash scripts/setup-signing.sh && bash scripts/build-app.sh && cp -R dist/DockAnchor.app /Applications/ && open /Applications/DockAnchor.app
```

Move the app to `/Applications` (or `~/Applications`) before enabling Launch at Login so
it registers against a stable path.

### Stable signing

`scripts/setup-signing.sh` creates a self-signed code-signing identity
(`DockAnchor Self-Signed`) in your login keychain, and `build-app.sh` uses it
automatically. This gives every build the same signature.

macOS ties Accessibility grants to an app's signing identity. Plain ad-hoc signing
produces a new identity on every build, so macOS keeps forgetting the permission. A
stable identity means you grant Accessibility once and it persists across rebuilds. The
script is safe to re-run and needs no admin password (it intentionally does not add the
cert to the Gatekeeper trust store; only a stable signature is required).

If you skip it, `build-app.sh` falls back to ad-hoc signing and everything still works,
you'll just be re-prompted for Accessibility after rebuilds.

## First launch & permissions

On first launch DockAnchor prompts for Accessibility automatically. Enable it under
**System Settings → Privacy & Security → Accessibility**; the guard activates the moment
you do, no restart needed. You can re-trigger the prompt anytime via **Grant Accessibility
Permission…** in the menu.

## Usage

Everything lives in the menu-bar item:

- **Enabled**: turn the cursor barrier on/off.
- **Lock Dock to ▸**: pick the display the Dock is pinned to (defaults to the main
  display).
- **Launch at Login**: start DockAnchor automatically (on by default after first run).
- **Quit**.

## Troubleshooting

- **Still says "Needs Permission" after toggling it on.** The Accessibility list has a
  stale entry from an earlier build with a different signature. Reset it and grant fresh:

  ```sh
  osascript -e 'quit app "DockAnchor"' 2>/dev/null
  tccutil reset Accessibility com.abbo.dockanchor
  open /Applications/DockAnchor.app
  ```

  Then toggle it on once more. The stable signing identity (above) prevents this from
  recurring. If multiple "DockAnchor" rows show in the list, remove them all with the "-"
  button before re-granting.
- **App icon looks generic in Finder.** macOS caches app icons aggressively. It usually
  refreshes after the app is moved to `/Applications` and reopened.

## Configuration notes

- The guarded band is ~2px. That bottom strip on non-selected displays becomes
  unreachable by the cursor; it's reserved for Dock triggering anyway, and the band is
  kept small to minimize any effect on dragging windows to that edge.
- The bundle identifier is `com.abbo.dockanchor`. If you publish your own fork, change it
  in `Resources/Info.plist`.

## Development

```
Sources/DockAnchor/
  main.swift          NSApplication bootstrap (.accessory policy)
  AppDelegate.swift   Status item, menu, lifecycle, screen-change handling
  DockGuard.swift     CGEventTap + cursor-clamp logic (the core)
  DisplayStore.swift  Display enumeration + selection persisted by UUID
  Permissions.swift   Accessibility check / prompt
  LaunchAtLogin.swift SMAppService login-item wrapper
scripts/
  build-app.sh        Build + assemble the .app + code sign
  setup-signing.sh    Create the stable self-signed identity (one-time)
  generate-icon.swift Render the app icon artwork
  generate-icon.sh    Build Resources/AppIcon.icns from the renderer
```

Build for development with:

```sh
swift build           # or: swift build -c release
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.

## License

[MIT](LICENSE) © Peter Abbondanzo
