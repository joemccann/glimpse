import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?

    var statusItem: NSStatusItem?
    var panel: NSPanel?
    var preferencesWindow: NSWindow?
    var eventMonitor: Any?

    // Size constraints
    static let minWidth: CGFloat = 500
    static let minHeight: CGFloat = 400
    static let maxWidth: CGFloat = 1400
    static let maxHeight: CGFloat = 1000
    static let defaultWidth: CGFloat = 800
    static let defaultHeight: CGFloat = 750

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        performAutoCleanupIfEnabled()
        setupMenuBar()
    }

    /// Auto-cleanup completed sessions on launch if enabled in preferences
    private func performAutoCleanupIfEnabled() {
        let autoRemove = UserDefaults.standard.bool(forKey: "autoRemoveCompletedSessions")
        guard autoRemove else { return }

        let claudeDirectory = UserDefaults.standard.string(forKey: "claudeDirectory")
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".claude").path

        let sessionManager = SessionManager(claudeDirectory: claudeDirectory)
        sessionManager.loadSessions()
        let deleted = sessionManager.deleteCompletedSessions()

        if deleted > 0 {
            print("Auto-cleanup: Removed \(deleted) completed session(s)")
        }
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            // Load custom menu bar icon from bundle
            if let iconPath = Bundle.main.path(forResource: "menubar", ofType: "png"),
               let icon = NSImage(contentsOfFile: iconPath) {
                icon.isTemplate = true
                icon.size = NSSize(width: 18, height: 18)
                button.image = icon
            } else {
                // Fallback to system symbol if custom icon not found
                button.image = NSImage(systemSymbolName: "diamond", accessibilityDescription: "Claude Tasks")
            }
            button.action = #selector(togglePanel)
            button.target = self

            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        setupPanel()
    }

    private func setupPanel() {
        // Load saved size or use defaults
        let width = UserDefaults.standard.double(forKey: "panelWidth")
        let height = UserDefaults.standard.double(forKey: "panelHeight")

        let panelWidth = width > 0 ? CGFloat(width) : Self.defaultWidth
        let panelHeight = height > 0 ? CGFloat(height) : Self.defaultHeight

        // Create resizable panel with popover-like behavior (no title bar, not draggable)
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            styleMask: [.resizable, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel?.isFloatingPanel = true
        panel?.level = .floating
        panel?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel?.isMovableByWindowBackground = false  // Not draggable
        panel?.hidesOnDeactivate = false
        panel?.hasShadow = true
        panel?.backgroundColor = .clear

        // Set size constraints
        panel?.minSize = NSSize(width: Self.minWidth, height: Self.minHeight)
        panel?.maxSize = NSSize(width: Self.maxWidth, height: Self.maxHeight)

        // Set content
        let hostingView = NSHostingView(rootView: MenuBarView())
        panel?.contentView = hostingView

        // Observe resize events to save size
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(panelDidResize),
            name: NSWindow.didResizeNotification,
            object: panel
        )
    }

    @objc private func panelDidResize(_ notification: Notification) {
        guard let panel = panel else { return }
        let size = panel.frame.size
        UserDefaults.standard.set(Double(size.width), forKey: "panelWidth")
        UserDefaults.standard.set(Double(size.height), forKey: "panelHeight")
    }

    @objc func togglePanel(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            guard let panel = panel, let button = statusItem?.button else { return }

            if panel.isVisible {
                closePanel()
            } else {
                // Position panel below menu bar item
                let buttonRect = button.window?.convertToScreen(button.convert(button.bounds, to: nil)) ?? .zero
                let panelSize = panel.frame.size

                let x = buttonRect.midX - panelSize.width / 2
                let y = buttonRect.minY - panelSize.height - 5

                panel.setFrameOrigin(NSPoint(x: x, y: y))
                panel.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)

                // Add event monitor to close panel when clicking outside
                startEventMonitor()
            }
        }
    }

    private func startEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, let panel = self.panel, panel.isVisible else { return }

            // Check if click is outside the panel
            let screenLocation = NSEvent.mouseLocation

            if !panel.frame.contains(screenLocation) {
                // Also check it's not clicking the menu bar button
                if let button = self.statusItem?.button,
                   let buttonWindow = button.window {
                    let buttonRect = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
                    if !buttonRect.contains(screenLocation) {
                        self.closePanel()
                    }
                } else {
                    self.closePanel()
                }
            }
        }
    }

    private func stopEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func showContextMenu() {
        guard let button = statusItem?.button else { return }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        statusItem?.menu = menu
        button.performClick(nil)
        statusItem?.menu = nil
    }

    @objc func openPreferences() {
        // Close panel first
        panel?.orderOut(nil)

        if preferencesWindow == nil {
            let preferencesView = PreferencesView()
            let hostingController = NSHostingController(rootView: preferencesView)

            preferencesWindow = NSWindow(contentViewController: hostingController)
            preferencesWindow?.title = "Glimpse Preferences"
            preferencesWindow?.styleMask = [.titled, .closable]
            preferencesWindow?.setContentSize(NSSize(width: 450, height: 380))
            preferencesWindow?.center()
            preferencesWindow?.isReleasedWhenClosed = false
        }

        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func closePanel() {
        stopEventMonitor()
        panel?.orderOut(nil)
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }
}
