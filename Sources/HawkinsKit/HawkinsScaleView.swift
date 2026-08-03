import SwiftUI

/// Full 6-column reference table of the Map of Consciousness — Level, Log
/// score, Emotion, View of God, View of Life, Process — highest level first.
/// Pass `currentScore` to highlight the row that score falls into.
public struct HawkinsScaleView: View {
    private let currentScore: Int?

    public init(currentScore: Int? = nil) {
        self.currentScore = currentScore
    }

    private var currentID: String? {
        currentScore.map { Hawkins.level(for: $0).id }
    }

    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Hawkins.scale.reversed()) { level in
                    row(for: level)
                    Divider()
                }
            }
        }
    }

    private func row(for level: HawkinsLevel) -> some View {
        let isCurrent = level.id == currentID
        return HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(level.color)
                .frame(width: 12, height: 12)
                .padding(.top, 3)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(level.name)
                        .font(.headline)
                    Text("\(level.logScore)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                    if isCurrent {
                        Image(systemName: "arrow.left")
                            .foregroundStyle(.tint)
                    }
                }
                Text("Emotion: \(level.emotion)")
                    .font(.caption)
                Text("View of God: \(level.viewOfGod)")
                    .font(.caption)
                Text("View of Life: \(level.viewOfLife)")
                    .font(.caption)
                Text("Process: \(level.process)")
                    .font(.caption)
            }
            .foregroundStyle(isCurrent ? .primary : .secondary)
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isCurrent ? level.color.opacity(0.12) : Color.clear)
    }
}
