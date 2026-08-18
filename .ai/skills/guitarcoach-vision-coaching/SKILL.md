---
name: guitarcoach-vision-coaching
description: Design, implement, test, or evaluate GuitarCoach's on-device camera and finger-position feedback. Use for AVFoundation, Vision, Core ML, coordinate geometry, confidence gating, model evaluation, and feedback ranking work.
---

# Build trustworthy coaching

1. Define the target exercise and observable evidence before choosing a model.
2. Keep capture, detection, coordinate transforms, target comparison, and feedback ranking separate.
3. Every inference output includes confidence and failure reason. Below threshold, render a setup/reposition cue—not a correction.
4. Start with Apple Vision and deterministic geometry for static shapes. Add a model only when evaluation proves a gap.
5. Test transforms and ranking with fixtures; evaluate latency, setup coverage, and known failure modes by device, handedness, and instrument conditions.

Never persist camera frames by default or make an accuracy claim without measured evidence. Use `references/evaluation-card.md` for experiments.
