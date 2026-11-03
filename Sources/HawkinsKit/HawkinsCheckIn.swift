import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

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

/// Check-in sheet, compact by default: the preselected answer (`initial`,
/// usually the remembered last one) is a single row — "Feeling ● Peace · 600 ›"
/// — so accepting it is one tap on Save. Tapping the row pushes the full
/// Hawkins list (highest first); picking a level pops straight back. An
/// optional 0–10 slider and any `extra` sections the app adds (a note, a
/// rating) follow. Skip and Save in the toolbar; it dismisses itself.
/// Swiping it away saves only if an answer was changed — an untouched
/// preselection isn't recorded as if it were given.
///
/// Save always commits: it ends text editing first, so a focused note's
/// last word reaches the app's draft before `onSave` reads it; calls
/// `onSave` exactly once; shows a checkmark (with a success haptic); then
/// dismisses. It never goes dead — if a dismissal is dropped, tapping Save
/// again retries the dismiss instead of being ignored.
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
    /// `onSave` or `onSkip` has run (or is about to); neither runs twice.
    @State private var resolved = false
    /// Save went through — drives the checkmark and the haptic.
    @State private var saved = false

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
                    NavigationLink {
                        HawkinsLevelChoice(question: question,
                                           score: Binding(get: { score }, set: { score = $0; touched = true }))
                    } label: {
                        feelingRow
                    }
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
                    Button("Skip") { finish(save: false) }
                        .disabled(saved)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { finish(save: true) } label: {
                        if saved {
                            Label("Saved", systemImage: "checkmark")
                        } else {
                            Text("Save")
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .sensoryFeedback(.success, trigger: saved)
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 360)
        #endif
        .onDisappear {
            // Swipe-away: keep a changed answer, skip an untouched one.
            guard !resolved else { return }
            resolved = true
            touched ? onSave(answer) : onSkip()
        }
    }

    /// "Feeling  ● Peace · 600" — the current answer, one tap from changing.
    private var feelingRow: some View {
        let level = Hawkins.level(for: score)
        return HStack {
            Text("Feeling")
            Spacer()
            Circle()
                .fill(level.color)
                .frame(width: 10, height: 10)
            Text("\(level.name) · \(score)")
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Choose a different feeling")
    }

    /// Ends editing, then runs `onSave`/`onSkip` once and dismisses. A repeat
    /// tap after that only retries the dismiss, so the button never goes dead.
    private func finish(save: Bool) {
        guard !resolved else {
            dismiss()
            return
        }
        resolved = true
        endTextEditing()
        Task { @MainActor in
            // Let the field resign and hand over its final text (autocorrect,
            // marked text) before the app's callback reads its draft.
            try? await Task.sleep(for: .milliseconds(50))
            if save {
                onSave(answer)
                saved = true
                // Long enough to see the checkmark, well under 400 ms total.
                try? await Task.sleep(for: .milliseconds(250))
            } else {
                onSkip()
            }
            dismiss()
        }
    }
}

/// The full Hawkins list behind the compact row. Picking a level pops back
/// to the check-in, so changing the answer is two taps.
private struct HawkinsLevelChoice: View {
    let question: String
    @Binding var score: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section(question) {
                HawkinsPicker(score: Binding(get: { score }, set: { score = $0; dismiss() }),
                              order: .descending)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Feeling")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

/// Resigns whatever text field is first responder, so its pending text is
/// committed and the keyboard is going away before the sheet dismisses.
@MainActor
private func endTextEditing() {
    #if canImport(UIKit)
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    #elseif canImport(AppKit)
    NSApp.keyWindow?.makeFirstResponder(nil)
    #endif
}

#Preview("Check-in") {
    HawkinsCheckInSheet(question: "What did you feel while visualizing?",
                        intensityTitle: "How vivid was it?",
                        initial: .init(score: 600, intensity: 6),
                        onSave: { print($0) },
                        extra: {
                            Section("Note") {
                                TextField("How did it go?", text: .constant(""), axis: .vertical)
                            }
                        })
}
