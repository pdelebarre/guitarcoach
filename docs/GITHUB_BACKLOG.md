# GitHub planning backlog

The bootstrap script creates the following milestones, labels, epics, and linked implementation tasks. Epics use the `type: epic` label; GitHub's native sub-issues can be added from the issue UI after import, or tasks can be linked to the parent epic with `Relates to #…`.

## Milestones

- M0 Discovery & prototype
- M1 Technical foundation
- M2 Guided chord MVP
- M3 Beta quality
- M4 App Store launch
- M5 Growth learning loops

## Epics and tasks

| Epic | Planned tasks |
| --- | --- |
| Product discovery & trust | Learner research; measurement plan; static-chord usability prototype; privacy/age-appropriate review |
| Apple app foundation | SwiftUI app shell; local curriculum/progress; camera capture; CI and release automation |
| On-device coaching | Reference geometry; hand/neck pipeline; confidence/error taxonomy; feedback UI; evaluation harness |
| Practice experience | Onboarding/device setup; chord curriculum; attempt flow; progress; accessibility and left-handed mode |
| Identity, sync & monetization | Local-only mode; Sign in with Apple; private CloudKit sync; StoreKit paywall and entitlement tests |
| Beta, launch & growth | TestFlight; App Store assets/ASO; privacy-safe analytics; support ops; lifecycle experiments |

## Definition of done for every task

- Acceptance criteria are met and covered by appropriate automated or manual checks.
- Accessibility and privacy impact are reviewed.
- Telemetry is consent-aware and excludes raw image/landmark/biometric data.
- Failure or low-confidence states are designed and tested.

