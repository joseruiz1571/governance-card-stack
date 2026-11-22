# Changelog

Release versions number the repository. The Agent Card spec carries its own version in `spec_version`. It is `0.1.0` in every tagged release below and `0.2.0` in the unreleased work.

## Unreleased

### Added

- **Claimed versus verified (Agent Card spec 0.2.0).** An evidence item can declare a `basis`: `attestation`, `inspection`, or `test`. The gate warns when an `implemented` control cites no evidence with basis `inspection` or `test`, and treats an item with no `basis` as attestation. The Card carries no `verified` field; the gate derives it. The README section of the same name gives the reason, with the November 2026 zero data retention findings as the worked case, and says what `basis` does not prove.
- The gate accepts `spec_version` `0.1.0` and `0.2.0`. The change is additive, so a 0.1.0 Card stays valid. The sample Card moves to 0.2.0 and its evidence item declares `basis: test`.
- README status line: the project stays paused with no work scheduled. It no longer says the Agent Card gets bug fixes only, since 0.2.0 added a field.

### Fixed

- **The gate now checks that references resolve.** A control could cite an `evidence_refs` UUID that matched no `evidence[]` item and still pass, because the policy only counted the entries. The same was true of a threat's `mitigated_by` and a tool's `threat_refs`. All three now deny when an entry names nothing. UUIDs match without regard to case.

### Changed

- The sample Card's `next_review` moved to 2027-12-31 so the quickstart keeps passing while the project is paused. The README status line says what happens after that date.
- README: `mltrack card export` and `mltrack card validate` are marked shipped (mltrack v0.1.0). An earlier edit had listed them as dropped.

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
