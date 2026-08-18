---
applyTo: "**/*.swift"
---

Use Swift concurrency correctly: make UI state `@MainActor`; isolate camera/inference work off the main actor; propagate cancellation. Keep SwiftUI views thin and put business rules in testable domain types. Model vision results with explicit confidence and a failure reason. Unit-test coordinate transforms, target comparison, confidence thresholds, and feedback ranking. Avoid force unwraps and silent error swallowing.

