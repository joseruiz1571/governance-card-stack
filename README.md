# Governance Card Stack

**Machine-readable governance for AI.** Model, System, and Agent Cards as a single, OSCAL-aligned spine — so an AI system's governance posture is *data* a pipeline can gate on, an auditor can query, and another system can consume. Governance that produces data, not documents.

> Status: **v0.1.0 — draft.** This release ships the **Agent Card** schema and a worked example. Breaking changes expected until v1.0. Model Card and System Card schemas are next.

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
| **Model Card** | What a model *is*: purpose, training, performance, limitations, evaluations. | planned |
| **System Card** | The system *around* a model: data pipeline, deployment context, safeguards, human roles. | planned |
| **Agent Card** | What an agent is *allowed to do*: autonomy, tool/permission scope, decision boundaries, oversight, and the controls + evidence that back them. | **v0.1.0** |

The Agent Card ships first because it is the gap the field has not filled. Model Cards are well-established (Mitchell et al., 2019); System Cards less so; a *governance* Agent Card — an authority record for an autonomous system — barely exists yet.

---

## Repository layout

```
governance-card-stack/
├── README.md                              # this file (the spec front door)
├── schemas/
│   ├── agent-card.schema.json             # v0.1.0 — JSON Schema (draft 2020-12)
│   ├── system-card.schema.json            # planned
│   ├── model-card.schema.json             # planned
│   └── card-base.schema.json              # planned — shared metadata/governance/evidence defs
├── examples/
│   └── dispute-triage-agent.card.json     # worked Agent Card instance
└── docs/
    └── autonomy-levels.md                 # planned — the autonomy scale, expanded
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

The Card Stack is the spine where two existing projects converge:

- **[mltrack](https://github.com/joseruiz1571/mltrack)** is the **inventory / data layer** — it discovers and tracks governed models and (next) generates and validates Cards via a `card` export command. The Card schema is the format mltrack emits.
- **[cgep-capstone](https://github.com/joseruiz1571/cgep-capstone)** is the **evidence layer** — its CI pipeline produces Cosign-signed, Object-Lock-retained evidence bundles. A Card's `evidence[]` entries point at exactly those bundles.

A Card is what you get when an inventory entry and an evidence bundle are joined by a stable identifier.

---

## Design principles

- **Machine-first.** Every assertion is a field. Prose lives in `description`, never in place of structure.
- **OSCAL-aligned.** Stable v4 UUIDs, control references, evidence links, and a `props` escape hatch for cross-framework annotation — the same lineage as an OSCAL component definition.
- **Crosswalk-native.** Threats (MITRE ATLAS / OWASP) and controls (NIST AI RMF / ISO 42001 / SR 11-7) are first-class and cross-referenced. The crosswalk *is* the governance.
- **Evidence-linked and signable.** Cards reference signed evidence and can be signed themselves (canonicalize with RFC 8785 JCS, then sign — keyless Cosign works well).
- **Versioned.** `spec_version` on every Card; the schema is versioned in its `$id`.

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

---

## Roadmap

- [x] **v0.1.0** — Agent Card schema + worked example
- [ ] Extract `card-base.schema.json` (shared `metadata` / `governance` / `evidence` defs) and `$ref` it from all three cards
- [ ] **Model Card** and **System Card** schemas
- [ ] `mltrack card export` / `mltrack card validate` — generate and check Cards from the inventory
- [ ] A Conftest/OPA policy that fails a CI build when a changed agent ships without a valid, current Card (ties the stack to the capstone gate)
- [ ] `docs/autonomy-levels.md` — the autonomy scale, with worked examples per level
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

## License & author

MIT. Built by Jose Ruiz-Vazquez — *Controlled Vocabulary* (controlledvocabulary.substack.com). Building the data layer for AI governance.
