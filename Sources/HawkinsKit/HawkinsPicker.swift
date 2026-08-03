import SwiftUI

/// Manual picker for a Hawkins level: one row per level (color swatch, name,
/// log score), tapping a row sets `score` to that level's representative
/// `logScore`. Composed of plain rows (not its own `List`) so it drops
/// straight into a `Form`/`List` `Section` alongside other rows.
public struct HawkinsPicker: View {
    @Binding private var score: Int

    public init(score: Binding<Int>) {
        self._score = score
    }

    public var body: some View {
        ForEach(Hawkins.scale) { level in
            Button {
                score = level.logScore
            } label: {
                HStack {
                    Circle()
                        .fill(level.color)
                        .frame(width: 14, height: 14)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(level.name)
                            .foregroundStyle(.primary)
                        Text(level.emotion)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(level.logScore)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    if Hawkins.level(for: score).id == level.id {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.tint)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}

private struct HawkinsPickerPreviewContainer: View {
    @State private var score = 400

    var body: some View {
        List {
            Section("Calibration") {
                HawkinsPicker(score: $score)
            }
        }
    }
}

#Preview("Picker") {
    HawkinsPickerPreviewContainer()
}
