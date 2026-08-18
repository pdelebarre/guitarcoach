# Product requirements

## Users and jobs

| User | Need | Success signal |
| --- | --- | --- |
| Beginning student | Know where and how to place fingers for a chord or exercise | Completes a guided attempt with one actionable correction |
| Developing student | Practise efficiently between lessons | Sees an improving accuracy/streak trend over time |
| Teacher/parent | Recommend a focused practice plan without handling sensitive video | Shares an exercise plan and reviews consented summaries |

## MVP outcome

Within 90 seconds, a learner selects a chord, aligns their fretting hand in the camera frame, gets live positioning guidance, completes a 15–30 second attempt, and receives a ranked set of no more than three feedback items.

## Functional requirements

### Practice and curriculum

1. Provide a curated starter path: device setup, open-string posture, C/G/D/Em/Am chords, chord changes, and first rhythm patterns.
2. Each exercise defines target frets, strings, expected finger, hand orientation, difficulty, success thresholds, and plain-language hints.
3. Support a timed attempt, pause/resume, retry, and a short post-attempt summary.
4. Store progress, attempt scores, confidence, and the learner's chosen goal locally; sync only account-level progress when signed in.

### Vision coaching

1. Use the rear camera preview with a setup overlay for distance, rotation, lighting, and hand visibility.
2. Detect a fretting hand, key hand landmarks, guitar neck region, and fret/string reference geometry.
3. Estimate each fingertip's string/fret cell and report a confidence level.
4. Classify only bounded, explainable cues in MVP: wrong fret, wrong string, finger too far from fret, missing finger, excessive hand rotation, and occlusion/low confidence.
5. Never present low-confidence inference as a correction; ask for repositioning instead.
6. Run inference at an adaptive frame rate and maintain a responsive 30 fps preview on supported devices.

### Feedback and accessibility

1. Prioritize feedback by learning impact and confidence; show at most three items after an attempt.
2. Use visual, text, VoiceOver, and optional haptic cues. Avoid colour as the only signal.
3. Include a left-handed mode that mirrors setup guidance and maps the reference model correctly.
4. Let learners silence live prompts and review feedback after playing.

### Accounts, privacy, and safety

1. Permit local-only use without account creation.
2. Use Sign in with Apple for optional account sync.
3. Obtain camera permission just in time, state the processing purpose, and process frames in memory.
4. Separate minor/guardian flows; no direct messaging, public profiles, advertising IDs, or third-party tracking SDKs in MVP.
5. Provide export and deletion of synced learning data. Diagnostic-media upload is opt-in, off by default, and separately consented.

### Business and marketing requirements

1. App Store positioning: “See the next small correction, then play it better.”
2. Free onboarding gives the first chord path and two guided assessments; paid tier unlocks structured paths, history, and teacher-ready progress summaries.
3. Measure activation only with privacy-preserving events: completed device check, first assessment, first improvement, day-7 practice. Do not collect raw frames or biometric identifiers for analytics.
4. Build App Store assets around a 15-second “before → correction → improvement” story and searchable phrases such as “learn guitar chords” and “guitar finger placement.”

## Quality attributes and acceptance targets

| Area | Target |
| --- | --- |
| Latency | Live cue shown within 250 ms of an analyzable frame on supported iPhone/iPad hardware |
| Reliability | Graceful “reposition device” state instead of a false correction below configured confidence |
| Privacy | No raw camera frames persisted by default; analytics contains no images, landmarks, or unique biometric template |
| Availability | Core practice works offline after content download |
| Accessibility | VoiceOver, Dynamic Type, reduced motion, captions/text equivalents, haptic alternatives |
| Observability | Crash-free sessions, inference latency buckets, confidence distribution, funnel events—all consent-aware |

## Decisions to validate in discovery

- Accuracy for standard versus left-handed guitar setups, acoustic versus electric neck profiles, and common lighting conditions.
- Whether the first release should assess static chord shapes only, or include strumming/audio alignment.
- The threshold at which a user considers a cue trustworthy and non-distracting.
- Subscription willingness versus teacher/lesson-studio licensing.

