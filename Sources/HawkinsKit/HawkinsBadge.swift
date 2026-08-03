import SwiftUI

/// Small capsule showing a Hawkins level's color and name — for inline
/// display anywhere a scored item is listed.
public struct HawkinsBadge: View {
    private let level: HawkinsLevel

    public init(score: Int) {
        self.level = Hawkins.level(for: score)
    }

    public var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(level.color)
                .frame(width: 8, height: 8)
            Text(level.name)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(level.color.opacity(0.15), in: Capsule())
    }
}
