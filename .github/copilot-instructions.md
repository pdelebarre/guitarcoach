# GuitarCoach Copilot instructions

Follow `AGENTS.md` first. Read only the relevant product document and GitHub issue before proposing work.

Use a vertical-slice approach. For every implementation response, give: intended outcome, acceptance criteria, minimal plan, changed files, verification, and remaining risk. Keep proposed work under one focused story; split larger work into issues.

This is an Apple-first, privacy-first mobile app. Use SwiftUI and Apple frameworks. Camera analysis is on-device by default; do not persist raw frames or emit hand/face/landmark data to analytics. Vision output must carry confidence and render a setup/reposition state below threshold. Support VoiceOver, Dynamic Type, reduced motion, haptic alternatives, offline use, and left-handed mode.

Do not invent API capabilities, product metrics, clinical claims, or accuracy results. Do not add third-party SDKs, cloud services, telemetry, or dependencies without explaining the data flow and obtaining approval. Prefer small, testable components and deterministic geometry over opaque heuristics for the static-chord MVP.

Keep output token-efficient: cite paths and issue numbers, use short decision tables only when comparing options, and avoid reproducing repository content.

