import Foundation
import ServiceManagement

/// Wraps SMAppService for registering the app as a login item.
/// Registration is reliable only when the .app lives in a stable location
/// (e.g. /Applications or ~/Applications).
enum LaunchAtLogin {

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func set(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("DockAnchor: LaunchAtLogin toggle failed: \(error.localizedDescription)")
        }
    }
}
