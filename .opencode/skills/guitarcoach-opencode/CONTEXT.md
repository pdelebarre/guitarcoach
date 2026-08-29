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

## Shared context schema

All agents must use this exact structure:

```yaml
context:
  goal: "1–2 sentence task goal"
  files:
    - "path/to/file.swift"
  constraints:
    - "constraint bullet"
    step: "reading | designing | writing | validating"
```

Rules:
- Context is always passed in full to every subtask.
- Agents must NOT repeat the entire context in their outputs.
- Agents update context via deltas only (see below).

## Context delta format

When an agent changes understanding or plan, it outputs a `context_delta` block:

```yaml
context_delta:
  files_added:
    - "new/path.swift"
  files_removed:
    - "old/path.swift"
  constraints_added:
    - "new constraint"
  step: "new_step_value"  # optional
  goal_revision: "revised 1–2 sentence goal"  # optional, rare
```

Orchestrator applies deltas to produce the new `context` for the next subtask.

## History summary

For long conversations, orchestrator maintains a `history_summary`:

- 3–6 bullets summarizing:
  - key decisions
  - files changed
  - open questions
- Replaces detailed older turns when context grows large.

Specialists see:
- `context` (full)
- `history_summary` (if present)
- their own `subtask`

They do NOT see the full raw conversation history.
