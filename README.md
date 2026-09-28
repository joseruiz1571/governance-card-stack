# Governance Card Stack

**Machine-readable governance for AI.** Model, System, and Agent Cards on one OSCAL spine — so posture is *data* a pipeline can gate on, an auditor can query, and another system can consume. Governance that produces data, not documents.

> Status: **release v0.2.0, draft.** The Agent Card spec is at **0.1.0**: schema, worked example, and a CI gate. Breaking changes expected until v1.0. Model Card and System Card schemas are stubs. Changes by release: [CHANGELOG.md](CHANGELOG.md).

---

## Quickstart

Five minutes, using the sample Card that ships in `examples/`.

**1. Get the tools.** The gate needs `opa`, `jq`, and `check-jsonschema`. It runs on the bash that ships with macOS and Linux.

```bash
# macOS
brew install opa jq
pipx install check-jsonschema

# Linux: install opa from openpolicyagent.org, then
sudo apt-get install -y jq
pipx install check-jsonschema
```

**2. Clone and run the gate.**

```bash
git clone https://github.com/joseruiz1571/governance-card-stack.git
cd governance-card-stack
./scripts/card-gate.sh
```

The sample Card is valid and governed, so the gate passes:

```
Found 1 Card(s).
────────────────────────────────────────────────────────────
Card: examples/dispute-triage-agent.card.json
  card_type: agent
  schema:    schemas/agent-card.schema.json
ok -- validation done
  policy:    governance.agent_card
  PASS: no denials.
────────────────────────────────────────────────────────────
Card gate passed: 1 Card(s) valid and current.
```

**3. Break a Card and watch the gate deny it.** Copy the sample and switch off its kill switch. The agent is high risk, so the policy refuses it.

```bash
jq '.escalation.kill_switch.available = false' \
  examples/dispute-triage-agent.card.json > examples/broken.card.json
./scripts/card-gate.sh
```

The gate now finds two Cards. The sample still passes, and the broken one is denied:

```
Card: examples/broken.card.json
  card_type: agent
  schema:    schemas/agent-card.schema.json
ok -- validation done
  policy:    governance.agent_card
  DENY: HIGH/CRITICAL agents must declare an available kill switch (escalation.kill_switch.available = true).
...
Card gate FAILED — see DENY lines above.
```

The script exits 1, which is what fails a CI build. Clean up:

```bash
rm examples/broken.card.json
```

**4. Write your own.** Copy the sample to `examples/<your-agent>.card.json`, edit it, and run the gate again. Every identifier must be a v4 UUID (`uuidgen | tr 'A-Z' 'a-z'`). [docs/autonomy-levels.md](docs/autonomy-levels.md) defines the autonomy values.

---

## Why this exists

AI governance today produces documents. Model Cards as PDFs, risk assessments in wikis, control narratives in spreadsheets — artifacts no pipeline can read, no auditor can query, and no agent can consume. The information is real; the *format* is the problem.

The Governance Card Stack treats this as a cataloging problem. Give every governed thing a stable identifier, a structured schema, and explicit cross-references between the threats it faces and the controls that answer them — then serialize it so machines can act on it. A controlled vocabulary for AI governance.

Three claims hold the stack together:

1. **Governance is data.** A Card is a structured record, not prose. If a control can't be expressed as a field, it isn't yet a control.
2. **Authority control applies to AI.** Stable identifiers and crosswalks between vocabularies (threats ↔ controls, framework ↔ framework) are exactly what cataloging has done for a century. AI governance is the old problem with new infrastructure.
3. **A Card is evidence.** Every Card links to signed, timestamped, tamper-evident artifacts and can itself be signed. Assertions resolve to receipts.

---

## The three cards

| Card | Describes | Status |
|------|-----------|--------|
| **Model Card** | What a model *is*: purpose, training, performance, limitations, evaluations. | stub |
| **System Card** | The system *around* a model: data pipeline, deployment context, safeguards, human roles. | stub |
| **Agent Card** | What an agent is *allowed to do*: autonomy, tool/permission scope, decision boundaries, oversight, and the controls + evidence that back them. | **v0.1.0** |

The Agent Card ships first because it is the gap the field has not filled. Model Cards are well-established (Mitchell et al., 2019); System Cards less so; a *governance* Agent Card — an authority record for an autonomous system — barely exists yet.

---

## Repository layout

```
governance-card-stack/
├── README.md                              # this file (the spec front door)
├── CHANGELOG.md                           # what changed in each release
├── CONTRIBUTING.md                        # how to contribute, and the framework-text rule
├── LICENSE                                # Apache-2.0: schemas, policies, scripts, workflows
├── LICENSES/CC-BY-4.0.txt                 # CC BY 4.0: README, docs, example Cards
├── schemas/
│   ├── agent-card.schema.json             # v0.1.0 — JSON Schema (draft 2020-12)
│   ├── system-card.schema.json            # stub — card_type: "system"
│   ├── model-card.schema.json             # stub — card_type: "model"
│   └── card-base.schema.json              # planned — shared metadata/governance/evidence defs
├── examples/
│   └── dispute-triage-agent.card.json     # worked Agent Card instance
├── policies/
│   ├── agent_card.rego                    # OPA/Conftest CI gate — governance lint (run after schema validation)
│   └── agent_card_test.rego               # unit tests — `opa test policies/ -v`
├── scripts/
│   └── card-gate.sh                       # the gate: schema, then policy, over every Card
├── .github/workflows/
│   └── card-gate.yml                      # runs the gate on every push and pull request
└── docs/
    └── autonomy-levels.md                 # normative reference for autonomy_level / human_oversight / reversibility
```

---

## The Agent Card

An **Agent Card is an authority record for an autonomous system**: a stable, versioned, machine-readable description of what an agent may do and the governance that constrains it. It captures the dimensions that don't appear on a Model Card because they are properties of *action*, not of a model:

- **Autonomy** — a named autonomy level (`assistive` → `autonomous`) plus the human-oversight posture (`in_the_loop` / `on_the_loop` / `out_of_the_loop`) and the reversibility of the agent's actions.
- **Tools & permission scope** — each granted tool, what data it touches (read/write), its scope, whether it needs approval, and how reversible it is.
- **Decision boundaries** — explicit allow/deny/limit constraints with thresholds and a defined behavior on breach (block / escalate / halt).
- **Escalation** — the conditions that hand control back to a human, the target, the SLA, and the kill switch.
- **Governance spine** — control mappings (NIST AI RMF, ISO 42001, SR 11-7, …) and threat mappings (MITRE ATLAS, OWASP LLM Top 10), each cross-referenced to the other.
- **Evidence** — signed, hashed, retained artifacts the assertions resolve to.

### Not the same as an A2A Agent Card

The A2A protocol also defines an "Agent Card," but it answers a different question. A2A's card is a **capability and discovery** descriptor — an agent's identity, skills, endpoints, and auth, published at `/.well-known/agent-card.json` so other agents can find and call it. It is a digital business card.

This **Governance Agent Card is an assurance descriptor** — what the agent is *permitted* to do, under which controls, with what evidence. The two are complementary and meant to coexist: an Agent Card here can `link` to the agent's A2A capability card. (Both, notably, are signed over canonicalized JSON — A2A uses RFC 8785 JCS, and so should you.)

---

## How it connects to the rest of the work

The Card Stack is the spine between inventory and assurance. The order is inventory, then this spine, then signed custody and assessment:

- **[mltrack](https://github.com/joseruiz1571/mltrack)** is the **inventory**. It discovers and tracks governed models against NIST AI RMF, ISO 42001, and SR 11-7, and (next) generates and validates Cards via a `card` export command. The Card schema is the format that export emits.
- **[Colophon](https://github.com/joseruiz1571/colophon)** is **signed agent session custody**. It signs a session packet for agent tool use that a stranger can verify.
- **[mlassure](https://github.com/joseruiz1571/mlassure)** is **assurance**. It runs citation-invariant assessment: a verdict that cites evidence the run never retrieved fails the run.

mltrack names what is governed. A Card states the posture. Colophon keeps the signed session. mlassure assesses it.

**[cgep-capstone](https://github.com/joseruiz1571/cgep-capstone)** is related prior work: compliance-as-code, and a signed evidence vault whose CI pipeline produces Cosign-signed, Object-Lock-retained bundles. A Card's `evidence[]` entries can point at those bundles.

---

## Design principles

- **Machine-first.** Every assertion is a field. Prose lives in `description`, never in place of structure.
- **OSCAL-aligned.** Stable v4 UUIDs, control references, evidence links, and a `props` escape hatch for cross-framework annotation — the same lineage as an OSCAL component definition.
- **Crosswalk-native.** Threats (MITRE ATLAS / OWASP) and controls (NIST AI RMF / ISO 42001 / SR 11-7) are first-class and cross-referenced. The crosswalk *is* the governance.
- **Evidence-linked and signable.** Cards reference signed evidence and can be signed themselves (canonicalize with RFC 8785 JCS, then sign — keyless Cosign works well).
- **Versioned.** `spec_version` on every Card; the schema is versioned in its `$id`.

### Framework references: identifiers and your own words

ISO/IEC 42001 is copyrighted, and this repository reproduces none of its text. A control mapping carries the framework name, the control or clause identifier in `control_id`, and the Card author's own commentary in `statement`. The commentary describes how the agent meets the control. It never restates the control. The same rule covers every other framework that does not allow redistribution. Details in [CONTRIBUTING.md](CONTRIBUTING.md#referencing-frameworks-ids-and-your-own-words).

---

## Validate a Card

The schema is JSON Schema **draft 2020-12**. Validate an instance with any compliant validator:

```bash
# Python
pip install check-jsonschema
check-jsonschema --schemafile schemas/agent-card.schema.json examples/dispute-triage-agent.card.json

# Node
npx ajv-cli validate -s schemas/agent-card.schema.json -d "examples/*.card.json" --spec=draft2020
```

Note the v4-UUID constraint on identifiers, mirroring OSCAL — hand-written all-zero UUIDs will fail, by design.

### The CI gate

Schema validation answers *is this well-formed*. The Rego policy in `policies/`
answers *is this governed* — staleness, risk-tier obligations, dangling threats,
autonomy coherence. `scripts/card-gate.sh` runs both, in that order, over every
`*.card.json` in the repo:

```bash
./scripts/card-gate.sh          # needs opa, check-jsonschema, jq
```

The ordering is load-bearing, not stylistic. The policy's rules assume the
schema has already guaranteed that `classification` and `risk_tier` exist and
are well-typed; on an unvalidated card those rules go *undefined* rather than
true, so the gate would pass a malformed Card. A schema failure therefore stops
that Card before the policy runs.

`.github/workflows/card-gate.yml` runs the same script on every push to `main`
and every pull request, after `opa test policies/ -v` and an `opa fmt` check.
`deny` fails the build; `warn` prints and does not. The gate also fails when it
finds no Cards at all — a gate that passes on an empty set is not a gate.

The workflow calls `opa eval` rather than Conftest. The policy is a clean
Conftest fit and `conftest test examples/*.card.json --policy policies/
--all-namespaces` gives identical results, but Conftest has no first-party
setup action to pin by commit SHA, and OPA is the same engine underneath.

---

## Roadmap

- [x] **v0.1.0** — Agent Card schema + worked example
- [ ] Extract `card-base.schema.json` (shared `metadata` / `governance` / `evidence` defs) and `$ref` it from all three cards
- [x] **Model Card** and **System Card** schemas (stubs — full field expansion follows the `card-base` extraction)
- [ ] `mltrack card export` / `mltrack card validate` — generate and check Cards from the inventory
- [x] A Conftest/OPA policy that fails a CI build when a changed agent ships without a valid, current Card (ties the stack to the capstone gate)
- [x] `docs/autonomy-levels.md` — the autonomy scale, with worked examples per level
- [ ] Publish the spec at a stable URL and invite a first external adopter

---

## Related work

- **A2A Agent Card** — capability/discovery descriptor for agent interoperability. Complementary; this Card is the assurance layer that can reference it.
- **Model Cards** — Mitchell et al., *Model Cards for Model Reporting* (2019). The Model Card schema here is a structured, evidence-linked descendant.
- **MITRE ATLAS** — adversarial threat taxonomy for AI (e.g., `AML.T0051` LLM Prompt Injection, `AML.T0110` AI Agent Tool Poisoning). Used as a `threat_mappings` vocabulary.
- **OWASP Top 10 for LLM Applications** — e.g., `LLM06 Excessive Agency`, directly relevant to agent governance.
- **NIST AI RMF** and **ISO/IEC 42001** — control vocabularies for `control_mappings`.
- **OSCAL** — the serialization lineage (catalogs, components, assessment results) this format borrows from.

---

## Maintenance posture

Single maintainer, best-effort. Issues and pull requests are read; response time is not guaranteed.

---

## License & author

Two licenses, split by path.

| Paths | License |
|-------|---------|
| `schemas/`, `policies/`, `scripts/`, `.github/` | [Apache-2.0](LICENSE) |
| `README.md`, `CONTRIBUTING.md`, `docs/`, `examples/` | [CC BY 4.0](LICENSES/CC-BY-4.0.txt) |

Anything not listed falls under Apache-2.0. Releases v0.1.0 and v0.1.1 were published under MIT and stay available on those terms. v0.2.0 is the first release under the licenses above.

Built by Jose Ruiz-Vazquez — *Controlled Vocabulary* (controlledvocabulary.substack.com). Evidence and assurance for agent governance: Model, System, and Agent Cards on one OSCAL spine, so posture is data a pipeline can gate on.
