import SwiftUI

struct AppearanceSettingsView: View {
    @ObservedObject var settings: CursorSettings

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    PreviewCursorView(settings: settings)
                    Spacer()
                }
                .padding(.bottom, 8)
            }

            Section("Shape") {
                Picker("Shape", selection: $settings.shape) {
                    ForEach(HighlightShape.allCases) { shape in
                        Text(shape.displayName).tag(shape)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Size") {
                HStack {
                    Text("\(Int(settings.highlightSize)) pt")
                        .frame(width: 50, alignment: .leading)
                        .monospacedDigit()
                    Slider(value: $settings.highlightSize, in: 20...200, step: 5)
                }
            }

            Section("Highlight Border") {
                HStack {
                    Text(String(format: "%.1f pt", settings.borderWidth))
                        .frame(width: 50, alignment: .leading)
                        .monospacedDigit()
                    Slider(value: $settings.borderWidth, in: 0.5...10, step: 0.5)
                }
            }

            Section("Color & Glow") {
                ColorPicker("Highlight Color", selection: highlightColorBinding, supportsOpacity: false)

                HStack {
                    Text("Glow Intensity")
                    Slider(value: $settings.glowIntensity, in: 0...1)
                }
            }

            Section("Cursor Type Colors") {
                Toggle("Change color by cursor type", isOn: $settings.cursorColorEnabled)

                if settings.cursorColorEnabled {
                    ColorPicker("Hand (links)", selection: handCursorColorBinding, supportsOpacity: false)
                    ColorPicker("Text (I-beam)", selection: iBeamCursorColorBinding, supportsOpacity: false)
                }
            }

            Section("Click Animation") {
                ColorPicker("Left Click", selection: leftClickColorBinding, supportsOpacity: false)
                ColorPicker("Right Click", selection: rightClickColorBinding, supportsOpacity: false)

                HStack {
                    Text(String(format: "%.1f pt", settings.clickBorderWidth))
                        .frame(width: 50, alignment: .leading)
                        .monospacedDigit()
                    Slider(value: $settings.clickBorderWidth, in: 0.5...10, step: 0.5)
                }
            }

            Section("Cursor Offset") {
                HStack {
                    Text("X: \(Int(settings.cursorOffsetX))")
                        .frame(width: 40, alignment: .leading)
                        .monospacedDigit()
                    Slider(value: $settings.cursorOffsetX, in: -20...20, step: 1)
                }
                HStack {
                    Text("Y: \(Int(settings.cursorOffsetY))")
                        .frame(width: 40, alignment: .leading)
                        .monospacedDigit()
                    Slider(value: $settings.cursorOffsetY, in: -20...20, step: 1)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
    }

    private var highlightColorBinding: Binding<Color> {
        Binding(
            get: { Color(nsColor: settings.highlightColor) },
            set: { settings.highlightColor = NSColor($0) }
        )
    }

    private var leftClickColorBinding: Binding<Color> {
        Binding(
            get: { Color(nsColor: settings.leftClickColor) },
            set: { settings.leftClickColor = NSColor($0) }
        )
    }

    private var rightClickColorBinding: Binding<Color> {
        Binding(
            get: { Color(nsColor: settings.rightClickColor) },
            set: { settings.rightClickColor = NSColor($0) }
        )
    }

    private var handCursorColorBinding: Binding<Color> {
        Binding(
            get: { Color(nsColor: settings.handCursorColor) },
            set: { settings.handCursorColor = NSColor($0) }
        )
    }

    private var iBeamCursorColorBinding: Binding<Color> {
        Binding(
            get: { Color(nsColor: settings.iBeamCursorColor) },
            set: { settings.iBeamCursorColor = NSColor($0) }
        )
    }
}
