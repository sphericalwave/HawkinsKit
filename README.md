# HawkinsKit

Swift package for David Hawkins' Map of Consciousness ("Power vs. Force") — a
17-level, log-scale (0–1000) scale from Shame to Enlightenment, with a
programmatic color ramp and drop-in SwiftUI views.

## Usage

```swift
import HawkinsKit

Hawkins.scale                    // all 17 levels, ascending
Hawkins.level(for: 425)          // -> Reason
Hawkins.color(for: 425)          // gradient Color for that score
```

### Views

- `HawkinsBadge(score: Int)` — small color-coded capsule with the level name.
- `HawkinsPicker(score: Binding<Int>)` — rows for all 17 levels; tap to set
  `score` to that level's representative log score. Drop into a `Form`/`List`
  `Section`.
- `HawkinsScaleView(currentScore: Int? = nil)` — full reference table
  (Level, Log score, Emotion, View of God, View of Life, Process), highest
  level first, optionally highlighting the row containing `currentScore`.
- `HawkinsCheckInSheet` — after-the-fact "What did you feel?" sheet. Compact:
  the preselected answer (`HawkinsCheckInMemory`'s last one) is a single
  "Feeling ● Peace · 600 ›" row, so accepting it is one tap on Save; tap the
  row to pick from the full list. Save ends text editing first, calls
  `onSave` once, shows a checkmark, then dismisses.

## Platforms

iOS 17+, macOS 14+.
