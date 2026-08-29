# opencode

OpenAgents skill for code-oriented tasks in the guitarcoach repo.

## Purpose

Help with reading, writing, refactoring, and explaining Swift code in the CoachingEngine and GuitarCoach modules, plus related scripts and docs.

## Agents

- `opencode-orchestrator` — routes tasks to specialized agents and maintains shared context.
- `opencode-reader` — read-only code understanding, navigation, and summarization.
- `opencode-writer` — safe, incremental code edits and new file creation.
- `opencode-architect` — higher-level design, module boundaries, and API shape.

All agents share a common context block and are optimized for DeepSeek-class models (flash/max), avoiding more expensive models unless explicitly requested.

## Best practices

- Orchestrator is the single entry point; specialists never talk directly to the user.
- Shared context is minimal, structured, and delta-only.
- Model routing: flash by default, max only when truly needed.
- Strict output templates to keep tokens low and outputs composable.
- Explicit stop-and-ask rules to avoid wasted work.
- Incremental, testable changes; validation step after writes.
- Periodic conversation compression for long sessions.
