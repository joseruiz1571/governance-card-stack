# Changelog

Release versions number the repository. The Agent Card spec carries its own version in `spec_version`, which is `0.1.0` in every release below.

## v0.2.0 (2026-09-28)

### Changed

- **License.** Code moves from MIT to Apache-2.0: schemas, policies, scripts, and workflows. README, docs, and example Cards are now CC BY 4.0. Earlier releases stay available under MIT.
- The sample Card's review dates were moved forward so it passes the staleness rule.

### Added

- **Card gate in CI.** `scripts/card-gate.sh` validates every `*.card.json` against the schema for its `card_type`, then evaluates the Rego policy. `.github/workflows/card-gate.yml` runs it on every push to `main` and every pull request, after `opa test` and an `opa fmt` check. The gate fails when it finds no Cards.
- **Quickstart** in the README: install, run the gate on the sample Card, break a Card, watch the deny.
- **CONTRIBUTING.md**, with the rule for copyrighted frameworks such as ISO/IEC 42001: identifiers and the author's own commentary, never the control text. The schema descriptions for `control_id` and `statement` say the same.
- **Maintenance posture** in the README.
- This changelog.

### Fixed

- `scripts/card-gate.sh` runs on bash 3.2, the version macOS ships.

## v0.1.1 (2026-06-06)

### Added

- OPA/Rego policy for Agent Cards (`policies/agent_card.rego`) with unit tests.
- Model Card and System Card schema stubs.
- `docs/autonomy-levels.md`, the reference for `autonomy_level`, `human_oversight`, and `reversibility`.

## v0.1.0 (2026-06-06)

### Added

- Agent Card schema (JSON Schema, draft 2020-12).
- Worked example: `examples/dispute-triage-agent.card.json`.
