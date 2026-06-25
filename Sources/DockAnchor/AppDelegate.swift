import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private let dockGuard = DockGuard()
    private let displayStore = DisplayStore()
    private var permissionTimer: Timer?

    private var enabled: Bool {
        get { UserDefaults.standard.object(forKey: "Enabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "Enabled") }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()

        dockGuard.dockEdge = DockGuard.currentDockEdge()
        dockGuard.selectedDisplayID = displayStore.resolvedSelectedDisplayID()

        startGuardIfPossible()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "menubar.dock.rectangle",
                accessibilityDescription: "DockAnchor"
            )
        }
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        rebuildMenu()
    }

    private func startGuardIfPossible() {
        guard enabled, Permissions.isTrusted else { return }
        if !dockGuard.isRunning {
            dockGuard.start()
        }
    }

    // MARK: - Notifications

    @objc private func screensChanged() {
        dockGuard.dockEdge = DockGuard.currentDockEdge()
        dockGuard.selectedDisplayID = displayStore.resolvedSelectedDisplayID()
        rebuildMenu()
    }

    // MARK: - Menu

    private func rebuildMenu() {
        guard let menu = statusItem.menu else { return }
        menu.removeAllItems()

        let trusted = Permissions.isTrusted
        let statusTitle: String
        if !trusted {
            statusTitle = "DockAnchor: Needs Permission"
        } else if enabled && dockGuard.isRunning {
            statusTitle = "DockAnchor: Active"
        } else {
            statusTitle = "DockAnchor: Paused"
        }
        let statusLine = NSMenuItem(title: statusTitle, action: nil, keyEquivalent: "")
        statusLine.isEnabled = false
        menu.addItem(statusLine)

        menu.addItem(.separator())

        let enabledItem = NSMenuItem(title: "Enabled", action: #selector(toggleEnabled), keyEquivalent: "")
        enabledItem.target = self
        enabledItem.state = enabled ? .on : .off
        menu.addItem(enabledItem)

        let lockItem = NSMenuItem(title: "Lock Dock to", action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        let selected = dockGuard.selectedDisplayID
        let mainID = CGMainDisplayID()
        for display in displayStore.activeDisplays() {
            let suffix = display.id == mainID ? "  (Main)" : ""
            let item = NSMenuItem(
                title: display.name + suffix,
                action: #selector(selectDisplayAction(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = NSNumber(value: display.id)
            item.state = display.id == selected ? .on : .off
            submenu.addItem(item)
        }
        lockItem.submenu = submenu
        menu.addItem(lockItem)

        menu.addItem(.separator())

        let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = LaunchAtLogin.isEnabled ? .on : .off
        menu.addItem(loginItem)

        if !trusted {
            let permItem = NSMenuItem(
                title: "Grant Accessibility Permission…",
                action: #selector(grantPermission),
                keyEquivalent: ""
            )
            permItem.target = self
            menu.addItem(permItem)
        }

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit DockAnchor", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    // MARK: - Actions

    @objc private func toggleEnabled() {
        enabled.toggle()
        if enabled {
            startGuardIfPossible()
        } else {
            dockGuard.stop()
        }
        rebuildMenu()
    }

    @objc private func selectDisplayAction(_ sender: NSMenuItem) {
        guard let number = sender.representedObject as? NSNumber else { return }
        let id = number.uint32Value as CGDirectDisplayID
        displayStore.selectDisplay(id)
        dockGuard.selectedDisplayID = id
        rebuildMenu()
    }

    @objc private func toggleLaunchAtLogin() {
        LaunchAtLogin.set(!LaunchAtLogin.isEnabled)
        rebuildMenu()
    }

    @objc private func grantPermission() {
        Permissions.promptForAccessibility()
        Permissions.openSettings()

        permissionTimer?.invalidate()
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            if Permissions.isTrusted {
                timer.invalidate()
                self.permissionTimer = nil
                self.startGuardIfPossible()
                self.rebuildMenu()
            }
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
    }
}
