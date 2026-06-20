//
//  MathInputSheetView+DrawingSettings.swift
//  ExcalidrawZ
//
//  Created by Codex on 2026/06/19.
//

import SwiftUI

extension MathInputSheetView {
    @ViewBuilder
    var drawingSettings: some View {
        switch activeWorkspace {
            case .equation, .geometry:
                colorControls
            case .function:
                functionDrawingSettings
        }
    }

    var functionDrawingSettings: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("AXIS SETTINGS")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(1.2)

            LazyVGrid(
                columns: [
                    .init(.flexible(), spacing: 12),
                    .init(.flexible(), spacing: 12)
                ],
                alignment: .leading,
                spacing: 10
            ) {
                functionTextField("X min", text: $functionXMin)
                functionTextField("X max", text: $functionXMax)
                functionTextField("Y min", text: $functionYMin)
                functionTextField("Y max", text: $functionYMax)
                functionTextField("X label", text: $functionXLabel)
                functionTextField("Y label", text: $functionYLabel)
            }

            Toggle("Show grid", isOn: $functionShowGrid)

            HStack(alignment: .center, spacing: 10) {
                Text("BACKGROUND")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(1.2)
                    .frame(width: 96, alignment: .leading)

                ColorButtonGroup(
                    colors: ColorPalette.backgroundQuickPicks,
                    selectedColor: functionBackgroundColor ?? "transparent"
                ) { color in
                    functionBackgroundColor = color == "transparent" ? nil : color
                }
            }
        }
    }

    func functionTextField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField(title, text: text)
                .textFieldStyle(.roundedBorder)
        }
    }
}
