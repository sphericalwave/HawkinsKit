import SwiftUI

/// A single row of David Hawkins' Map of Consciousness ("Power vs. Force").
public struct HawkinsLevel: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let logScore: Int
    public let scoreRange: ClosedRange<Int>
    public let emotion: String
    public let viewOfGod: String
    public let viewOfLife: String
    public let process: String

    public var color: Color { Hawkins.color(for: logScore) }
}

public enum Hawkins {

    /// The 17 levels, ascending by log score.
    public static let scale: [HawkinsLevel] = [
        HawkinsLevel(id: "shame", name: "Shame", logScore: 20, scoreRange: 0...29,
                     emotion: "Humiliation", viewOfGod: "Despising", viewOfLife: "Miserable", process: "Elimination"),
        HawkinsLevel(id: "guilt", name: "Guilt", logScore: 30, scoreRange: 30...49,
                     emotion: "Blame", viewOfGod: "Vindictive", viewOfLife: "Evil", process: "Destruction"),
        HawkinsLevel(id: "apathy", name: "Apathy", logScore: 50, scoreRange: 50...74,
                     emotion: "Despair", viewOfGod: "Condemning", viewOfLife: "Hopeless", process: "Abdication"),
        HawkinsLevel(id: "grief", name: "Grief", logScore: 75, scoreRange: 75...99,
                     emotion: "Regret", viewOfGod: "Disdainful", viewOfLife: "Tragic", process: "Despondency"),
        HawkinsLevel(id: "fear", name: "Fear", logScore: 100, scoreRange: 100...124,
                     emotion: "Anxiety", viewOfGod: "Punitive", viewOfLife: "Frightening", process: "Withdrawal"),
        HawkinsLevel(id: "desire", name: "Desire", logScore: 125, scoreRange: 125...149,
                     emotion: "Craving", viewOfGod: "Denying", viewOfLife: "Disappointing", process: "Enslavement"),
        HawkinsLevel(id: "anger", name: "Anger", logScore: 150, scoreRange: 150...174,
                     emotion: "Hate", viewOfGod: "Vengeful", viewOfLife: "Antagonistic", process: "Aggression"),
        HawkinsLevel(id: "pride", name: "Pride", logScore: 175, scoreRange: 175...199,
                     emotion: "Scorn", viewOfGod: "Indifferent", viewOfLife: "Demanding", process: "Inflation"),
        HawkinsLevel(id: "courage", name: "Courage", logScore: 200, scoreRange: 200...249,
                     emotion: "Affirmation", viewOfGod: "Permitting", viewOfLife: "Feasible", process: "Empowerment"),
        HawkinsLevel(id: "neutrality", name: "Neutrality", logScore: 250, scoreRange: 250...309,
                     emotion: "Trust", viewOfGod: "Enabling", viewOfLife: "Satisfactory", process: "Release"),
        HawkinsLevel(id: "willingness", name: "Willingness", logScore: 310, scoreRange: 310...349,
                     emotion: "Optimism", viewOfGod: "Inspiring", viewOfLife: "Hopeful", process: "Intention"),
        HawkinsLevel(id: "acceptance", name: "Acceptance", logScore: 350, scoreRange: 350...399,
                     emotion: "Forgiveness", viewOfGod: "Merciful", viewOfLife: "Harmonious", process: "Transcendence"),
        HawkinsLevel(id: "reason", name: "Reason", logScore: 400, scoreRange: 400...499,
                     emotion: "Understanding", viewOfGod: "Wise", viewOfLife: "Meaningful", process: "Abstraction"),
        HawkinsLevel(id: "love", name: "Love", logScore: 500, scoreRange: 500...539,
                     emotion: "Reverence", viewOfGod: "Loving", viewOfLife: "Benign", process: "Revelation"),
        HawkinsLevel(id: "joy", name: "Joy", logScore: 540, scoreRange: 540...599,
                     emotion: "Serenity", viewOfGod: "One", viewOfLife: "Complete", process: "Transfiguration"),
        HawkinsLevel(id: "peace", name: "Peace", logScore: 600, scoreRange: 600...699,
                     emotion: "Bliss", viewOfGod: "All-Being", viewOfLife: "Perfect", process: "Illumination"),
        HawkinsLevel(id: "enlightenment", name: "Enlightenment", logScore: 700, scoreRange: 700...1000,
                     emotion: "Ineffable", viewOfGod: "Self", viewOfLife: "Is", process: "Pure Consciousness"),
    ]

    /// Clamps to 0...1000 and returns the level whose range contains the score
    /// (falling back to the closest level, which can only happen for scores
    /// below the first range's floor).
    public static func level(for score: Int) -> HawkinsLevel {
        let clamped = min(max(score, 0), 1000)
        if let match = scale.first(where: { $0.scoreRange.contains(clamped) }) {
            return match
        }
        return scale.min(by: { abs($0.logScore - clamped) < abs($1.logScore - clamped) })!
    }

    // MARK: - Color ramp

    private struct Stop {
        let score: Double
        let hue: Double
        let saturation: Double
        let brightness: Double
    }

    /// Fixed HSB control points the ramp interpolates between: dark maroon at
    /// the bottom, through red/orange/yellow across the Power/Force threshold
    /// (~200), green/blue through Love/Reason, violet approaching Peace, and
    /// desaturating to a warm white/gold at Enlightenment.
    private static let stops: [Stop] = [
        Stop(score: 0,    hue: 0.00, saturation: 0.80, brightness: 0.30),
        Stop(score: 75,   hue: 0.02, saturation: 0.85, brightness: 0.45),
        Stop(score: 150,  hue: 0.04, saturation: 0.90, brightness: 0.60),
        Stop(score: 200,  hue: 0.08, saturation: 0.85, brightness: 0.75),
        Stop(score: 250,  hue: 0.14, saturation: 0.75, brightness: 0.85),
        Stop(score: 400,  hue: 0.30, saturation: 0.60, brightness: 0.80),
        Stop(score: 500,  hue: 0.50, saturation: 0.55, brightness: 0.80),
        Stop(score: 600,  hue: 0.65, saturation: 0.55, brightness: 0.85),
        Stop(score: 800,  hue: 0.80, saturation: 0.30, brightness: 0.92),
        Stop(score: 1000, hue: 0.13, saturation: 0.05, brightness: 1.00),
    ]

    /// Gradient color for an arbitrary score, linearly interpolated in HSB
    /// between the fixed `stops`.
    public static func color(for score: Int) -> Color {
        let clamped = Double(min(max(score, 0), 1000))
        guard let upperIndex = stops.firstIndex(where: { $0.score >= clamped }) else {
            let last = stops[stops.count - 1]
            return Color(hue: last.hue, saturation: last.saturation, brightness: last.brightness)
        }
        guard upperIndex > 0 else {
            let first = stops[0]
            return Color(hue: first.hue, saturation: first.saturation, brightness: first.brightness)
        }
        let lower = stops[upperIndex - 1]
        let upper = stops[upperIndex]
        let span = upper.score - lower.score
        let t = span > 0 ? (clamped - lower.score) / span : 0
        return Color(
            hue: lower.hue + (upper.hue - lower.hue) * t,
            saturation: lower.saturation + (upper.saturation - lower.saturation) * t,
            brightness: lower.brightness + (upper.brightness - lower.brightness) * t
        )
    }
}
