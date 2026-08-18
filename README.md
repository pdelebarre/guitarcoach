# GuitarCoach

Apple-first guitar coaching that turns a learner's practice into clear, encouraging next actions. The initial product focuses on a single player, an iPhone or iPad camera, and right-handed fretted instruments in standard guitar tuning.

## Product promise

In one short practice session, a student can choose an exercise, position their device, receive understandable feedback on fretting-hand placement, and see one measurable improvement target for the next attempt.

## Repository guide

- [Product requirements](docs/PRODUCT_REQUIREMENTS.md)
- [Apple-first architecture](docs/ARCHITECTURE.md)
- [Delivery roadmap](docs/ROADMAP.md)
- [GitHub planning backlog](docs/GITHUB_BACKLOG.md)
- [GitHub bootstrap script](scripts/bootstrap-github-plan.sh)

## Privacy position

Camera analysis is on-device by default. Raw video is never required to leave the device; consent is explicit for any opt-in diagnostic clip sharing. The product must work for minors with a guardian-controlled account and without behavioural advertising.

## Explicit non-goals for the MVP

- Grading a player's musical expression or technique quality from a single video
- Persistent cloud video recording
- Automatic string/fret note identification at professional accuracy in every lighting condition
- Android or web client parity

