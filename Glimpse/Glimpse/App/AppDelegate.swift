import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
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
            button.action = #selector(togglePopover)
            button.target = self

            // Right-click menu
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ","))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        popover = NSPopover()
        popover?.contentSize = NSSize(width: 400, height: 500)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: MenuBarView())
    }

    @objc func togglePopover(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            guard let button = statusItem?.button, let popover = popover else { return }

            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.makeKey()
            }
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
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }
}
