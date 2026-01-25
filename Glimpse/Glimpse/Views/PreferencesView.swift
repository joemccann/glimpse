import SwiftUI

struct PreferencesView: View {
    @AppStorage("claudeDirectory") private var claudeDirectory = FileManager.default
        .homeDirectoryForCurrentUser.appendingPathComponent(".claude").path
    @AppStorage("notifyOnTaskComplete") private var notifyOnTaskComplete = true
    @AppStorage("notifyOnSessionComplete") private var notifyOnSessionComplete = true
    @AppStorage("notifyOnBlocked") private var notifyOnBlocked = false
    @AppStorage("theme") private var theme = "system"

    var body: some View {
        Form {
            Section("Claude Directory") {
                HStack {
                    TextField("Path", text: $claudeDirectory)
                        .textFieldStyle(.roundedBorder)

                    Button("Browse...") {
                        selectDirectory()
                    }
                }
            }

            Section("Notifications") {
                Toggle("Notify when task completes", isOn: $notifyOnTaskComplete)
                Toggle("Notify when session completes", isOn: $notifyOnSessionComplete)
                Toggle("Notify when task is blocked", isOn: $notifyOnBlocked)
            }

            Section("Appearance") {
                Picker("Theme", selection: $theme) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 300)
    }

    private func selectDirectory() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false

        if panel.runModal() == .OK, let url = panel.url {
            claudeDirectory = url.path
        }
    }
}
