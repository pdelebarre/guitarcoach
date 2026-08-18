# GuitarCoach agent contract

## Product boundaries

Build an Apple-first, on-device guitar-coaching app. The MVP assesses static fretting-hand chord shapes; it does not claim to judge musical expression. Preserve local-only use, explicit consent, and no raw camera-frame storage by default.

## Agile loop

1. Read `README.md`, the relevant `docs/` file, and the selected GitHub issue before acting.
2. Deliver one vertical slice at a time: user-visible outcome, smallest safe implementation, verification, and a concise issue update.
3. Keep work in progress to one active story per agent. Split work estimated above two focused sessions.
4. State assumptions and acceptance criteria before implementation; record unresolved product decisions in the issue, not code comments.
5. Finish with tests/checks run, risks, and the next smallest valuable slice.

## Engineering guardrails

- Prefer SwiftUI, SwiftData, AVFoundation, Vision, Core ML, CloudKit, StoreKit 2, and Apple platform APIs.
- Treat all camera/vision outputs as uncertain. Gate feedback on confidence and instruct repositioning rather than making a weak correction.
- Keep raw frames in memory; never add analytics that stores frames, landmarks, face/hand templates, or advertising identifiers.
- Make the offline path work before adding account, sync, or backend dependencies.
- Build accessibility in: VoiceOver labels, Dynamic Type, reduced motion, haptic alternatives, and left-handed mode.
- Do not add dependencies, upload data, change cloud settings, or publish releases without explicit authorization.

## Token-smart collaboration

- Read narrowly; use `rg` before opening files. Summarize findings rather than pasting whole files.
- Reuse `docs/` decisions and `.ai/skills/` rather than rediscovering standards.
- Keep plans to 3–6 concrete steps. Do not produce status narration with no decision or result.
- Prefer a focused diff and a targeted check over speculative refactors or broad scans.

## Definition of done

A story is done only when its acceptance criteria are met, verification is recorded, privacy/accessibility implications are checked, and the issue has a short handoff note.

