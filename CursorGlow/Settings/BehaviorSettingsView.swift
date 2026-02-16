import SwiftUI

struct BehaviorSettingsView: View {
    @ObservedObject var settings: CursorSettings

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
            }

            Section("Click Animation") {
                Toggle("Show click animation", isOn: $settings.clickAnimationEnabled)
                Toggle("Tilt on click", isOn: $settings.tiltOnClickEnabled)
            }

            Section("Auto-Hide") {
                Toggle("Auto-hide when idle", isOn: $settings.autoHideEnabled)

                if settings.autoHideEnabled {
                    HStack {
                        Text("Delay: \(String(format: "%.0fs", settings.autoHideDelay))")
                        Slider(value: $settings.autoHideDelay, in: 1...15, step: 1)
                    }
                }
            }

            Section("Keyboard Shortcut") {
                HStack {
                    Text("Toggle Highlight")
                    Spacer()
                    Text("Cmd + Shift + H")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(6)
                        .font(.system(.body, design: .monospaced))
                }
            }

            Section {
                Button("Restore Defaults") {
                    settings.restoreDefaults()
                }
                .frame(maxWidth: .infinity)
            }

            Section("Permissions") {
                HStack {
                    Text("Accessibility")
                    Spacer()
                    if PermissionsHelper.isAccessibilityGranted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Granted")
                            .foregroundColor(.secondary)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Button("Grant") {
                            PermissionsHelper.requestAccessibility()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }

            }
        }
        .formStyle(.grouped)
        .frame(width: 350)
    }
}
