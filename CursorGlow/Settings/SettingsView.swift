import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = CursorSettings.shared

    var body: some View {
        TabView {
            AppearanceSettingsView(settings: settings)
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }

            BehaviorSettingsView(settings: settings)
                .tabItem {
                    Label("Behavior", systemImage: "gearshape")
                }
        }
        .frame(minWidth: 400, minHeight: 420)
        .padding()
    }
}
