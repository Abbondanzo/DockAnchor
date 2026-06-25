# DockAnchor

A tiny macOS menu-bar app that **locks the Dock to one display**. On a multi-monitor
setup with the Dock set to auto-hide, macOS slides the Dock onto whichever screen you
push the cursor against at the bottom edge. DockAnchor stops that — the Dock stays on
the display you choose — **without** needing to turn off *Displays Have Separate Spaces*
(which forces a logout and removes per-display menu bars/spaces).

## How it works

The Dock's auto-show is decided by the WindowServer purely from the cursor's global
position; a transparent overlay window can't intercept it. Instead DockAnchor installs a
`CGEventTap` that watches mouse-move/drag events and, when the cursor enters the bottom
~2px of a **non-selected** display, nudges it back up a pixel. This builds an invisible
"floor" so the bottom-edge hit region of the other displays can never be reached, while
the selected display's edge is left untouched so the Dock works normally there.

This requires **Accessibility** permission (an active event tap that modifies events).

## Build & run

```sh
bash scripts/build-app.sh
open dist/DockAnchor.app
```

The app appears only in the menu bar (no Dock icon of its own). On first launch it
**prompts for Accessibility permission automatically** — enable DockAnchor in
*System Settings → Privacy & Security → Accessibility* and it activates as soon as you do.
(You can re-trigger the prompt later via **Grant Accessibility Permission…** in the menu.)
First launch also **enables Launch at Login by default**; toggle it off from the menu if
you prefer.

## Menu

- **Enabled** — turn the cursor barrier on/off.
- **Lock Dock to ▸** — pick which display the Dock is pinned to (defaults to the main
  display; the choice is remembered per display, even across reconnects).
- **Launch at Login** — start DockAnchor automatically (on by default after first run).
  For this to register reliably, move `DockAnchor.app` to `/Applications` or
  `~/Applications` first.
- **Quit**.

## Notes

- Works for the Dock at the **bottom** (default), and also **left**/**right** — it reads
  your current Dock position automatically.
- Tradeoff: the bottom ~2px of non-selected displays becomes unreachable by the cursor.
  That strip is reserved for Dock triggering anyway; the band is kept small to minimize
  any effect on dragging windows to that edge.
- The build is ad-hoc code-signed. After a rebuild that changes the signature, macOS may
  ask you to re-grant Accessibility permission. For a stable identity, sign with a
  self-signed or Developer ID certificate instead.

## Requirements

macOS 13+, Swift 5.9+ / Xcode toolchain.
