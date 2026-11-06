//
//  VehicleColorPicker.swift
//  SocketCD
//
//  Created by Justin Risner on 11/5/26.
//

import SwiftUI
import UIKit

/// A vehicle color button with preset swatches and the native custom color picker.
struct VehicleColorPicker: View {
    @Environment(\.self) private var environment
    @Binding var selectedColor: Color
    @State private var showingPalette = false

    private let presetRows: [[(name: LocalizedStringKey, color: Color)]] = [
        [("Red", .red), ("Orange", .orange), ("Yellow", .yellow), ("Green", .green), ("Teal", .teal), ("Blue", .blue)],
        [("Indigo", .indigo), ("Socket Purple", .socketPurple), ("Pink", .pink), ("Gray", .gray), ("Black", .black)]
    ]

    private var selectedPreset: Color? {
        let selected = selectedColor.resolve(in: environment)
        return presetRows.joined().first { preset in
            let color = preset.color.resolve(in: environment)
            // Allow for tiny rounding differences when a color returns from UIKit.
            return abs(selected.red - color.red) < 0.0001
                && abs(selected.green - color.green) < 0.0001
                && abs(selected.blue - color.blue) < 0.0001
                && abs(selected.opacity - color.opacity) < 0.0001
        }?.color
    }

    var body: some View {
        Button {
            showingPalette = true
        } label: {
            Label("Choose Color", systemImage: "paintpalette")
                .labelStyle(.iconOnly)
        }
        .accessibilityHint("Shows preset colors and a custom color picker")
        .popover(isPresented: $showingPalette, arrowEdge: .top) {
            palette
                .presentationCompactAdaptation(.popover)
        }
    }

    private var palette: some View {
        Grid(horizontalSpacing: 15, verticalSpacing: 15) {
            ForEach(presetRows.indices, id: \.self) { row in
                GridRow {
                    ForEach(presetRows[row], id: \.color) { preset in
                        Button {
                            selectedColor = preset.color
                        } label: {
                            swatch(preset.color, isSelected: selectedPreset == preset.color)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text(preset.name))
                        .accessibilityAddTraits(selectedPreset == preset.color ? .isSelected : [])
                    }
                    
                    if row == presetRows.count - 1 {
                        CustomColorWell(
                            selection: $selectedColor,
                            showsRainbow: selectedPreset != nil
                        )
                        .frame(width: CustomColorWell.nativeSize.width, height: CustomColorWell.nativeSize.height)
                        .scaleEffect(32 / CustomColorWell.nativeSize.width)
                        .frame(width: 44, height: 44)
                    }
                }
            }
        }
        .padding(20)
        .presentationBackground(Color(.systemBackground))
        .accessibilityAction(.escape) {
            showingPalette = false
        }
    }

    private func swatch(_ color: Color, isSelected: Bool) -> some View {
        Circle()
            .fill(color)
            .frame(width: 32, height: 32)
            .overlay {
                Circle()
                    .strokeBorder(.secondary.opacity(0.5), lineWidth: 0.75)
            }
            .overlay {
                Circle()
                    .strokeBorder(.quaternary, lineWidth: isSelected ? 2 : 0)
                    .frame(width: 40, height: 40)
            }
            .accessibilityHidden(true)
    }
}


private struct CustomColorWell: UIViewRepresentable {
    static let nativeSize = UIColorWell().intrinsicContentSize

    @Binding var selection: Color
    let showsRainbow: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection)
    }

    func makeUIView(context: Context) -> UIColorWell {
        let well = UIColorWell()
        well.supportsAlpha = false
        well.title = String(localized: "Custom Color")
        well.accessibilityLabel = String(localized: "Custom Color")
        well.addTarget(context.coordinator, action: #selector(Coordinator.colorChanged(_:)), for: .valueChanged)
        let rainbowWell = context.coordinator.rainbowWell
        rainbowWell.selectedColor = nil
        rainbowWell.isUserInteractionEnabled = false
        rainbowWell.accessibilityElementsHidden = true
        rainbowWell.isAccessibilityElement = false
        rainbowWell.frame = well.bounds
        rainbowWell.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        well.addSubview(rainbowWell)
        return well
    }

    func updateUIView(_ well: UIColorWell, context: Context) {
        context.coordinator.selection = $selection
        // The interactive well always seeds the picker with the actual selected color.
        let color = UIColor(selection)
        if well.selectedColor != color {
            well.selectedColor = color
        }
        context.coordinator.rainbowWell.isHidden = !showsRainbow
    }

    final class Coordinator: NSObject {
        let rainbowWell = UIColorWell()
        var selection: Binding<Color>

        init(selection: Binding<Color>) {
            self.selection = selection
        }

        @objc func colorChanged(_ well: UIColorWell) {
            guard let color = well.selectedColor else { return }
            selection.wrappedValue = Color(uiColor: color)
        }
    }
}

#Preview {
    @Previewable @State var selectedColor: Color = .socketPurple

    VehicleColorPicker(selectedColor: $selectedColor)
        .padding()
}

