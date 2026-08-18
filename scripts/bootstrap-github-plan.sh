#!/usr/bin/env bash
set -euo pipefail

# Creates milestones, labels, epics, and task issues in the named GitHub repo.
# Usage: ./scripts/bootstrap-github-plan.sh OWNER/REPOSITORY
repo="${1:?Usage: $0 OWNER/REPOSITORY}"

gh auth status >/dev/null

labels=(
  "type: epic|5319e7" "type: task|0e8a16" "area: product|d4c5f9"
  "area: ios|0075ca" "area: vision|fbca04" "area: privacy|b60205"
  "area: growth|f9d0c4" "priority: p0|b60205" "priority: p1|fbca04"
)
for item in "${labels[@]}"; do
  IFS='|' read -r label color <<<"$item"
  gh label create "$label" --repo "$repo" --color "$color" --force
done

milestone() { gh api --method POST "repos/$repo/milestones" -f title="$1" >/dev/null 2>&1 || true; }
for name in "M0 Discovery & prototype" "M1 Technical foundation" "M2 Guided chord MVP" "M3 Beta quality" "M4 App Store launch" "M5 Growth learning loops"; do milestone "$name"; done

issue() {
  local title="$1" labels="$2" milestone="$3" body="$4"
  gh issue create --repo "$repo" --title "$title" --label "$labels" --milestone "$milestone" --body "$body"
}

issue "Epic: Product discovery & learner trust" "type: epic,area: product,priority: p0" "M0 Discovery & prototype" "Own product validation, positioning, and privacy trust."
issue "Research learner workflows and willingness to pay" "type: task,area: product,priority: p0" "M0 Discovery & prototype" "Interview 8–12 guitar learners and 3–5 teachers. Deliver jobs, objections, and pricing hypotheses."
issue "Prototype and test device setup plus static chord assessment" "type: task,area: product,area: vision,priority: p0" "M0 Discovery & prototype" "Validate camera placement, comprehension, and perceived feedback trust with a clickable/functional prototype."
issue "Complete privacy, minor-safety, and data-flow review" "type: task,area: privacy,priority: p0" "M0 Discovery & prototype" "Document data inventory, consent, deletion/export, retention, and age-appropriate design decisions."

issue "Epic: Apple app foundation" "type: epic,area: ios,priority: p0" "M1 Technical foundation" "Establish an offline-capable iPhone/iPad application baseline."
issue "Create SwiftUI feature modules and local-first persistence" "type: task,area: ios,priority: p0" "M1 Technical foundation" "Implement app shell, navigation, SwiftData schema, seeded curriculum, and migration strategy."
issue "Implement camera capture lifecycle and preview diagnostics" "type: task,area: ios,area: vision,priority: p0" "M1 Technical foundation" "AVFoundation capture, permissions, orientation, frame throttling, and setup-quality overlay."
issue "Set up Xcode Cloud or GitHub Actions quality gates" "type: task,area: ios,priority: p1" "M1 Technical foundation" "Build, unit-test, lint, privacy manifest validation, and TestFlight-ready signing strategy."

issue "Epic: On-device coaching engine" "type: epic,area: vision,priority: p0" "M2 Guided chord MVP" "Deliver explainable, confidence-gated static chord feedback."
issue "Define guitar reference geometry and exercise target schema" "type: task,area: vision,priority: p0" "M2 Guided chord MVP" "Represent neck alignment, strings, frets, finger targets, tolerance, and hint mapping."
issue "Build hand-pose and neck-alignment inference pipeline" "type: task,area: vision,priority: p0" "M2 Guided chord MVP" "Use Vision/Core ML adapters and stable coordinate transforms; benchmark supported devices."
issue "Implement confidence gating and ranked feedback rules" "type: task,area: vision,priority: p0" "M2 Guided chord MVP" "Emit reposition guidance below threshold; limit result to three actionable cues."
issue "Create consented evaluation harness and model scorecard" "type: task,area: vision,area: privacy,priority: p1" "M2 Guided chord MVP" "Measure accuracy, latency, setup coverage, and failure modes without production raw-video collection."

issue "Epic: Guided practice experience" "type: epic,area: ios,priority: p0" "M2 Guided chord MVP" "Turn coaching evidence into a calm, accessible learner flow."
issue "Build onboarding and device-positioning guidance" "type: task,area: ios,priority: p0" "M2 Guided chord MVP" "Cover lighting, distance, orientation, and right/left-handed setup."
issue "Ship starter chord curriculum and timed attempt flow" "type: task,area: product,area: ios,priority: p0" "M2 Guided chord MVP" "C/G/D/Em/Am lessons, retry, pause, and per-attempt result."
issue "Add accessible feedback and left-handed mode" "type: task,area: ios,priority: p0" "M3 Beta quality" "VoiceOver, Dynamic Type, haptics alternatives, reduced motion, and mirrored coordinate mapping."
issue "Create progress history and next-best-practice recommendation" "type: task,area: ios,priority: p1" "M3 Beta quality" "Local trends and one next exercise based on observed confidence and completion."

issue "Epic: Identity, sync & monetization" "type: epic,area: ios,area: privacy,priority: p1" "M3 Beta quality" "Keep the app useful without an account while enabling secure optional sync."
issue "Implement local-only mode and Sign in with Apple" "type: task,area: ios,area: privacy,priority: p1" "M3 Beta quality" "No-account core use; account creation only when sync is requested."
issue "Add private CloudKit sync plus export/deletion controls" "type: task,area: ios,area: privacy,priority: p1" "M3 Beta quality" "Sync progress only; test conflict handling, export, and account deletion."
issue "Implement StoreKit 2 entitlements and paywall experiment" "type: task,area: ios,area: growth,priority: p1" "M4 App Store launch" "Free allowance, subscription state, restore purchases, and transparent value messaging."

issue "Epic: Beta, launch & growth" "type: epic,area: growth,priority: p1" "M4 App Store launch" "Validate the value loop, prepare the store, and operate a safe launch."
issue "Run TestFlight beta and resolve trust, accuracy, and performance gaps" "type: task,area: ios,area: vision,priority: p0" "M3 Beta quality" "Define success thresholds; triage feedback, crashes, latency, and misleading cues."
issue "Create App Store listing, screenshots, and ASO experiments" "type: task,area: growth,priority: p1" "M4 App Store launch" "Positioning, keywords, privacy disclosures, screenshots, and 15-second product story."
issue "Implement consent-aware activation and retention measurement" "type: task,area: growth,area: privacy,priority: p1" "M4 App Store launch" "Instrument aggregate-safe funnel without frames, landmarks, or ad tracking."
issue "Plan teacher/parent summaries and lifecycle experiments" "type: task,area: growth,area: product,priority: p1" "M5 Growth learning loops" "Validate sharing permissions, recurring practice nudges, and studio pricing."

echo "GitHub plan created in $repo"
