import Cocoa
import CoreGraphics

/// Which screen edge the Dock lives on (and therefore the edge whose hit
/// region we must guard on non-selected displays).
enum DockEdge {
    case bottom
    case left
    case right
}

/// Installs a CGEventTap that prevents the cursor from reaching the Dock's
/// hit region on any display other than the selected one. By nudging the
/// cursor back a couple of pixels at those edges, the WindowServer never
/// detects an edge press there, so the Dock stays anchored to the chosen
/// display.
final class DockGuard {

    /// Thickness (in points) of the invisible barrier kept at the guarded edge.
    var band: CGFloat = 2.0

    /// The display the Dock is locked to. The cursor is never clamped here.
    var selectedDisplayID: CGDirectDisplayID = CGMainDisplayID()

    /// The edge to guard, matching the user's Dock position.
    var dockEdge: DockEdge = .bottom

    private(set) var isRunning = false

    fileprivate var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    /// Creates and enables the event tap. Returns false if the tap could not
    /// be created — typically because Accessibility permission is not granted.
    @discardableResult
    func start() -> Bool {
        guard eventTap == nil else { return true }

        let mask: CGEventMask =
            (CGEventMask(1) << CGEventType.mouseMoved.rawValue) |
            (CGEventMask(1) << CGEventType.leftMouseDragged.rawValue) |
            (CGEventMask(1) << CGEventType.rightMouseDragged.rawValue) |
            (CGEventMask(1) << CGEventType.otherMouseDragged.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: dockAnchorEventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return false
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        eventTap = tap
        runLoopSource = source
        isRunning = true
        return true
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        if let tap = eventTap {
            CFMachPortInvalidate(tap)
        }
        eventTap = nil
        runLoopSource = nil
        isRunning = false
    }

    /// Re-enables the tap after the system disables it (timeout or user input).
    fileprivate func reEnable() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
    }

    /// Core clamp logic. Mutates the event's location in place when the cursor
    /// is inside the guarded band of a non-selected display.
    fileprivate func handle(_ event: CGEvent) {
        let location = event.location

        // Which display is the cursor on? Fall back to the selected display
        // (a no-op) if we can't tell.
        let displayID = Self.display(containing: location) ?? selectedDisplayID
        if displayID == selectedDisplayID { return }

        let bounds = CGDisplayBounds(displayID)
        var loc = location

        switch dockEdge {
        case .bottom:
            let edge = bounds.maxY            // bottom edge (top-left origin space)
            if loc.y >= edge - band {
                loc.y = edge - band - 1
                event.location = loc
            }
        case .left:
            let edge = bounds.minX
            if loc.x <= edge + band {
                loc.x = edge + band + 1
                event.location = loc
            }
        case .right:
            let edge = bounds.maxX
            if loc.x >= edge - band {
                loc.x = edge - band - 1
                event.location = loc
            }
        }
    }

    /// Returns the display containing a point in global (top-left origin) space.
    private static func display(containing point: CGPoint) -> CGDirectDisplayID? {
        var displayID = CGDirectDisplayID(0)
        var count: UInt32 = 0
        let result = CGGetDisplaysWithPoint(point, 1, &displayID, &count)
        guard result == .success, count > 0 else { return nil }
        return displayID
    }

    /// Reads the current Dock orientation from its preferences domain.
    static func currentDockEdge() -> DockEdge {
        let value = CFPreferencesCopyAppValue(
            "orientation" as CFString,
            "com.apple.dock" as CFString
        ) as? String
        switch value {
        case "left": return .left
        case "right": return .right
        default: return .bottom
        }
    }
}

/// C callback for the event tap. Recovers the DockGuard from `refcon`.
private func dockAnchorEventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
    let guardObject = Unmanaged<DockGuard>.fromOpaque(refcon).takeUnretainedValue()

    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        guardObject.reEnable()
        return Unmanaged.passUnretained(event)
    }

    guardObject.handle(event)
    return Unmanaged.passUnretained(event)
}
