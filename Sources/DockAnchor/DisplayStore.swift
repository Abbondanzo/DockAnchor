import Cocoa
import CoreGraphics

struct DisplayInfo {
    let id: CGDirectDisplayID
    let name: String
    let uuid: String
}

/// Enumerates connected displays and persists which one the Dock is locked to.
/// Selection is stored by display UUID, since CGDirectDisplayIDs are not stable
/// across reconnects.
final class DisplayStore {

    private let defaultsKey = "SelectedDisplayUUID"

    func activeDisplays() -> [DisplayInfo] {
        var count: UInt32 = 0
        guard CGGetActiveDisplayList(0, nil, &count) == .success, count > 0 else { return [] }

        var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetActiveDisplayList(count, &ids, &count) == .success else { return [] }

        return ids.prefix(Int(count)).map { id in
            DisplayInfo(id: id, name: name(for: id), uuid: uuidString(for: id) ?? "")
        }
    }

    func uuidString(for id: CGDirectDisplayID) -> String? {
        guard let cfUUID = CGDisplayCreateUUIDFromDisplayID(id)?.takeRetainedValue() else {
            return nil
        }
        return CFUUIDCreateString(kCFAllocatorDefault, cfUUID) as String
    }

    func name(for id: CGDirectDisplayID) -> String {
        for screen in NSScreen.screens {
            if let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber,
               number.uint32Value == id {
                return screen.localizedName
            }
        }
        return "Display \(id)"
    }

    var selectedUUID: String? {
        get { UserDefaults.standard.string(forKey: defaultsKey) }
        set { UserDefaults.standard.set(newValue, forKey: defaultsKey) }
    }

    /// Resolves the saved selection to a current display id, falling back to
    /// the main display if the saved display is no longer connected.
    func resolvedSelectedDisplayID() -> CGDirectDisplayID {
        if let saved = selectedUUID {
            for display in activeDisplays() where display.uuid == saved {
                return display.id
            }
        }
        return CGMainDisplayID()
    }

    func selectDisplay(_ id: CGDirectDisplayID) {
        selectedUUID = uuidString(for: id)
    }
}
