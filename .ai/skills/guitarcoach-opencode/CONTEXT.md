# Shared context for guitarcoach-opencode agents

## Project focus

- Primary codebase: `CoachingEngine/` (Swift package with geometry, chord shapes, feedback, hand observation, neck reference, starter chords).
- Secondary: `GuitarCoach/` app code, `scripts/`, and `docs/`.
- Language: Swift (iOS/macOS), some scripting (shell), and documentation (Markdown).

## Working principles

- Prefer small, composable changes over large rewrites.
- Keep changes consistent with existing Swift style and module boundaries.
- When proposing edits, show:
  - file path
  - short rationale
  - before/after snippet or unified diff
- Avoid speculative changes; ask if requirements are ambiguous.

## Model policy

- Default model class: DeepSeek flash/max tier (or equivalent cost/quality).
- Do not use more expensive models unless the user explicitly asks.
- Prefer concise reasoning and direct code over long monologues.

## Shared context block

When multiple agents collaborate, they should reuse this context summary:

- Task goal (1–2 sentences)
- Files involved (paths)
- Constraints (e.g., "no public API changes", "keep tests green")
- Current step (reading, designing, writing, validating)

Agents should append only deltas (what changed in understanding or plan), not repeat the whole context.
