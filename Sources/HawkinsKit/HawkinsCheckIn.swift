import SwiftUI

/// A quick after-the-fact check-in: "What did you feel?" on the Hawkins
/// scale (highest first), plus an optional 0–10 intensity/vividness rating.
/// Shared so every app asks it the same way and stores the same shape.
public enum HawkinsCheckIn {
    /// What the user answered. `intensity` is nil when the sheet didn't ask.
    public struct Answer: Equatable, Sendable {
        public var score: Int
        public var intensity: Int?

        public init(score: Int, intensity: Int? = nil) {
            self.score = score
            self.intensity = intensity
        }
    }

    public static let intensityRange = 0...10
}

/// The last answer given, kept in `UserDefaults` so the next check-in opens
/// on it — accepting the same answer is then one tap on Save.
public struct HawkinsCheckInMemory: Sendable {
    public let keyPrefix: String
    public let defaultScore: Int
    public let defaultIntensity: Int

    /// Keys are `<keyPrefix>LastScore` and `<keyPrefix>LastIntensity`.
    /// `defaultScore` 540 is Joy.
    public init(keyPrefix: String, defaultScore: Int = 540, defaultIntensity: Int = 5) {
        self.keyPrefix = keyPrefix
        self.defaultScore = defaultScore
        self.defaultIntensity = defaultIntensity
    }

    var scoreKey: String { keyPrefix + "LastScore" }
    var intensityKey: String { keyPrefix + "LastIntensity" }

    /// The last answer, or the defaults before any was given. Always carries
    /// an intensity, so a sheet that asks for one has something to preselect.
    public func last(in defaults: UserDefaults = .standard) -> HawkinsCheckIn.Answer {
        HawkinsCheckIn.Answer(
            score: defaults.object(forKey: scoreKey) as? Int ?? defaultScore,
            intensity: defaults.object(forKey: intensityKey) as? Int ?? defaultIntensity)
    }

    /// Remembers `answer` for next time. A nil intensity leaves the previous
    /// one remembered.
    public func remember(_ answer: HawkinsCheckIn.Answer, in defaults: UserDefaults = .standard) {
        defaults.set(answer.score, forKey: scoreKey)
        if let intensity = answer.intensity { defaults.set(intensity, forKey: intensityKey) }
    }

    /// What a check-in opens on: an existing answer (re-opening a past
    /// record) wins over the remembered one; intensity is clamped to 0–10.
    public static func initial(existing score: Int?, intensity: Int?,
                               last: HawkinsCheckIn.Answer) -> HawkinsCheckIn.Answer {
        let range = HawkinsCheckIn.intensityRange
        let chosen = intensity ?? last.intensity
        return HawkinsCheckIn.Answer(
            score: score ?? last.score,
            intensity: chosen.map { min(max($0, range.lowerBound), range.upperBound) })
    }
}

/// One-screen check-in sheet: the Hawkins picker (highest first, `initial`
/// preselected), an optional 0–10 slider, then any `extra` sections the app
/// adds (a note, a rating). Skip and Save in the toolbar; it dismisses
/// itself. Swiping it away saves only if an answer was changed — an
/// untouched preselection isn't recorded as if it were given.
public struct HawkinsCheckInSheet<Extra: View>: View {
    private let title: String
    private let question: String
    private let footer: String?
    private let intensityTitle: String?
    private let initial: HawkinsCheckIn.Answer
    private let onSave: (HawkinsCheckIn.Answer) -> Void
    private let onSkip: () -> Void
    private let extra: Extra

    @Environment(\.dismiss) private var dismiss
    @State private var score: Int
    @State private var intensity: Double
    @State private var touched = false
    @State private var resolved = false

    public init(title: String = "Check-in",
                question: String = "What did you feel?",
                footer: String? = nil,
                intensityTitle: String? = nil,
                initial: HawkinsCheckIn.Answer,
                onSave: @escaping (HawkinsCheckIn.Answer) -> Void,
                onSkip: @escaping () -> Void = {},
                @ViewBuilder extra: () -> Extra = { EmptyView() }) {
        self.title = title
        self.question = question
        self.footer = footer
        self.intensityTitle = intensityTitle
        self.initial = initial
        self.onSave = onSave
        self.onSkip = onSkip
        self.extra = extra()
        _score = State(initialValue: initial.score)
        _intensity = State(initialValue: Double(initial.intensity ?? 5))
    }

    private var answer: HawkinsCheckIn.Answer {
        HawkinsCheckIn.Answer(score: score, intensity: intensityTitle == nil ? nil : Int(intensity))
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    HawkinsPicker(score: Binding(get: { score }, set: { score = $0; touched = true }),
                                  order: .descending)
                } header: {
                    Text(question)
                } footer: {
                    if let footer { Text(footer) }
                }

                if let intensityTitle {
                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            LabeledContent(intensityTitle, value: "\(Int(intensity)) / 10")
                                .monospacedDigit()
                            Slider(value: Binding(get: { intensity }, set: { intensity = $0; touched = true }),
                                   in: Double(HawkinsCheckIn.intensityRange.lowerBound)...Double(HawkinsCheckIn.intensityRange.upperBound),
                                   step: 1)
                                .accessibilityLabel(intensityTitle)
                                .accessibilityValue("\(Int(intensity)) out of 10")
                        }
                    }
                }

                extra
            }
            .formStyle(.grouped)
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") { resolve(save: false) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { resolve(save: true) }
                        .fontWeight(.semibold)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 520)
        #endif
        .onDisappear {
            // Swipe-away: keep a changed answer, skip an untouched one.
            guard !resolved else { return }
            resolved = true
            touched ? onSave(answer) : onSkip()
        }
    }

    private func resolve(save: Bool) {
        guard !resolved else { return }
        resolved = true
        save ? onSave(answer) : onSkip()
        dismiss()
    }
}

#Preview("Check-in") {
    HawkinsCheckInSheet(question: "What did you feel while visualizing?",
                        intensityTitle: "How vivid was it?",
                        initial: .init(score: 540, intensity: 6),
                        onSave: { print($0) })
}
