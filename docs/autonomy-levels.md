# Autonomy Levels

> Part of the **Governance Card Stack**, spec **v0.1.0**. This document defines the `autonomy` block of the Agent Card (`autonomy_level`, `human_oversight`, `reversibility`) and is the normative reference for what those values mean.

---

## Why a controlled vocabulary for autonomy

"Autonomous" is the most overloaded word in agent governance. One team's *autonomous* agent asks permission before every write; another's rewrites production infrastructure unattended. When the word floats, nothing downstream can rely on it — a policy can't gate on it, an auditor can't test it, a second system can't consume it.

This document fixes the word. The Card Stack defines a small, ordered, named set of autonomy levels with operational definitions, so that `autonomy_level: "delegated"` means the same thing on every Card, in every repo, at every audit. That is authority control applied to autonomy: a stable heading with a fixed meaning, so the term can carry weight in machine-readable governance.

---

## Three axes, not one

The most common modeling error is treating "how autonomous is it?" as a single number. The Card separates three things that are routinely conflated:

1. **Autonomy level** — how much the agent *decides and acts* on its own. (This document.)
2. **Human oversight** — *where the human sits* relative to the agent's action loop. Orthogonal to autonomy; defined below.
3. **Reversibility / blast radius** — *how bad an unchecked action can get.* A risk input that bounds the other two.

A responsible configuration is a *combination* of all three. High blast radius (money moves, data leaves, safety) pushes oversight toward the loop and caps the autonomy level — no matter how capable the agent is. **Capability is never, by itself, a license for autonomy.** The autonomy level a system may run at is the *lower* of what the agent can do and what the surrounding controls can contain.

---

## The five autonomy levels

| Level | One line | Who decides | Who acts |
|-------|----------|-------------|----------|
| `assistive` | Proposes; a human decides and acts | Human | Human |
| `supervised` | Acts, but only on per-action human approval | Human (per action) | Agent |
| `delegated` | Acts within bounds; a human monitors and can intervene | Agent (within bounds) | Agent |
| `autonomous_bounded` | Acts independently inside hard constraints; humans engage only on exception | Agent (within constraints) | Agent |
| `autonomous` | Acts with minimal predefined constraints; broad discretion | Agent | Agent |

### `assistive`
**Definition.** The agent generates recommendations or drafts; a human makes every decision and performs every action. The agent is a thinking aid, not an actor.
**Human role.** In the loop, on every action — the human *is* the control.
**Example.** Drafts a dispute-resolution summary for an analyst to review, edit, and send. A coding assistant that proposes a diff a developer must apply.
**Governance.** Light. Inventory entry and a Model Card still apply, but no action-level guardrails are needed because nothing executes without a human.
**Failure mode.** Over-trust — humans rubber-stamp output without review, turning `assistive` into de-facto `supervised` without the controls. Watch for automation bias.

### `supervised`
**Definition.** The agent can *execute* actions, not merely suggest them, but each action is gated behind explicit human approval before it takes effect.
**Human role.** In the loop, approving each action.
**Example.** The agent prepares a provisional credit and a human clicks approve before it posts.
**Governance.** The approval gate is the primary control; log who approved what and when. Boundaries still matter as a backstop.
**Failure mode.** Approval fatigue — high volume turns approval into reflexive clicking. If you find yourself removing the per-action gate to keep up, you are actually at `delegated` and should govern it as such.

### `delegated`
**Definition.** The agent acts on its own within explicitly defined boundaries. A human is *on* the loop — monitoring, able to intervene, override, or halt — but not approving each action. Out-of-bounds situations escalate.
**Human role.** On the loop (supervisory), not in it.
**Example.** The reference [dispute-triage agent](../examples/dispute-triage-agent.card.json) auto-resolves disputes under \$500 and escalates everything above threshold or flagged for fraud; an analyst watches the queue and can pull it back.
**Governance.** Decision boundaries, escalation triggers, real-time monitoring, and a kill switch all become *required*, not optional. This is the first level where the controls — not a human's hands — do the containing.
**Failure mode.** Boundary gaps. A delegated agent is exactly as safe as its boundaries are complete; an unconsidered edge case is an unbounded action.

### `autonomous_bounded`
**Definition.** The agent acts independently with no human in or on the loop for in-bounds actions. Hard constraints and automated guardrails contain it; humans engage only when a boundary or escalation fires.
**Human role.** Out of the loop operationally; engaged on exception and after the fact (review, audit).
**Example.** A cost-remediation agent that auto-fixes within strict policy and pages a human only on exceptions; an AML alert-triager that auto-closes clear false positives and routes the rest.
**Governance.** Very strong boundaries, automated drift/anomaly detection, tamper-evident evidence *on every action*, tight review cadence, and a robust kill switch with rollback. The schema and the CI gate should require all of these.
**Failure mode.** Silent drift — because no human is watching in real time, a slowly degrading agent can do sustained damage before the next review. Continuous evidence and anomaly detection are the safeguard.

### `autonomous`
**Definition.** The agent acts with minimal predefined constraints and broad discretion, including self-directed sub-goals. Humans are out of the loop by default.
**Human role.** Out of the loop; post-hoc accountability only.
**Example.** An open-ended research or operations agent with broad tool access and few hard limits.
**Governance.** Exceptional. In most regulated contexts this should require documented, named risk acceptance (the CI gate enforces a `props` exception), continuous monitoring, and a hard kill switch. For systems touching money, PII/PHI, CUI, or safety, this level is rarely appropriate.
**Failure mode.** This *is* OWASP's **LLM06: Excessive Agency** by construction — too much autonomy, too-broad tools, too little oversight. Treat reaching for this level as a signal to re-examine whether the task actually requires it.

---

## Human oversight: the second axis

`human_oversight` records *where the human sits*, independent of the autonomy level:

- **`human_in_the_loop`** — a human acts *within* the decision/execution cycle; the agent cannot complete a governed action without human input (approval or execution). Pairs with `assistive` and `supervised`.
- **`human_on_the_loop`** — a human *supervises* in real or near-real time and can intervene, override, or halt, but does not approve each action. Pairs with `delegated`.
- **`human_out_of_the_loop`** — no human in the operational cycle; humans engage only on escalation or after the fact. Pairs with `autonomous_bounded` and `autonomous`.

These are *postures*, not quality grades. On-the-loop is not "better" than in-the-loop; it is appropriate for a different autonomy level. Choosing oversight is choosing where the human's leverage lives.

---

## Compatibility matrix

Not every autonomy × oversight pairing is coherent. Some are contradictions in terms.

| Autonomy level | `in_the_loop` | `on_the_loop` | `out_of_the_loop` |
|----------------|:---:|:---:|:---:|
| `assistive` | ✓ | ✗ | ✗ |
| `supervised` | ✓ | ⚠ | ✗ |
| `delegated` | ✗ | ✓ | ⚠ |
| `autonomous_bounded` | ✗ | ✓ | ✓ |
| `autonomous` | ✗ | ⚠ | ✓ |

**✓ coherent · ⚠ permitted with documented justification · ✗ contradictory.**

The contradictions are definitional. If a human approves every action, the agent is not `autonomous` — it is `supervised`, regardless of how it was labeled (high autonomy × `in_the_loop` = ✗). If no human is in or on the loop, the agent is not `assistive` or `supervised`, because those levels *require* a human to act or approve (low autonomy × `out_of_the_loop` = ✗). The ⚠ cells are real but should carry a reason: `supervised` × `on_the_loop` usually means you have drifted to `delegated`; `delegated` × `out_of_the_loop` is only defensible with guardrails strong enough that you are arguably at `autonomous_bounded`.

The CI gate (`policies/agent_card.rego`) hard-blocks the two clearest contradictions — high autonomy with `in_the_loop`, and low autonomy with `out_of_the_loop` — and points reviewers here for the rest.

---

## How the level drives the rest of the Card

The autonomy level sets the floor for the other Card fields. This is why the gate's requirements tighten as autonomy and risk rise.

| Field | `assistive` / `supervised` | `delegated` | `autonomous_bounded` / `autonomous` |
|-------|:---:|:---:|:---:|
| `decision_boundaries` | recommended | **required** | **required (hard limits)** |
| `escalation.triggers` | optional | **required** | **required** |
| `escalation.kill_switch` | recommended | **required** | **required (with rollback)** |
| Evidence per action | optional | recommended | **required** |
| Review cadence | annual–semiannual | quarterly | monthly or tighter |

Risk tier compounds this: a `delegated` agent at `critical` risk is governed like an `autonomous_bounded` one. When autonomy level and risk tier disagree, govern to the stricter of the two.

---

## Choosing the right level

Work top-down. Each answer sets a *ceiling* on autonomy and a *floor* on oversight; the final level is the most conservative result.

1. **Can a single unchecked action cause irreversible or material harm?** (Money moved, data exposed, a safety-relevant change.) → Cap at `supervised` or `delegated`; floor oversight at in/on-the-loop.
2. **Does the agent touch restricted or regulated data?** (PII, PHI, CUI.) → Raise evidence requirements and lower the autonomy ceiling.
3. **Is there direct regulatory exposure?** (SR 11-7, HIPAA, CMMC.) → Require documented boundaries and monitoring; `out_of_the_loop` needs named risk acceptance.
4. **How strong is the automated containment?** (Boundary coverage, anomaly detection, rollback.) → Strong containment is the *only* thing that earns a move from `delegated` to `autonomous_bounded`. Weak containment caps you regardless of the agent's capability.

If you cannot answer (4) with evidence, you are not yet at the level you want to claim.

---

## Relationship to existing frameworks

- **SAE J3016 (driving-automation levels)** — the inspiration for an ordered scale and for separating *who acts* from *who monitors*. The analogy is useful but breaks down: an agent's action space is open-ended, not bounded like driving, so a level here constrains *permissions and oversight*, not a fixed operational design domain. Borrow the structure, not the specifics.
- **NIST AI RMF** — its expectations around human oversight, accountability, and ongoing monitoring map onto the oversight axis and the review/evidence requirements above. The level is one input to MANAGE-function risk response.
- **OWASP Top 10 for LLM Applications — LLM06: Excessive Agency** — the canonical *failure* of mis-set autonomy: excessive functionality, permissions, or autonomy with insufficient oversight. This scale plus tight `decision_boundaries` and tool scoping is the mitigation.
- **MITRE ATLAS** — agent-specific techniques such as AI Agent Tool Poisoning (`AML.T0110`) and prompt injection (`AML.T0051`) grow more dangerous as autonomy rises and oversight falls. The level should drive threat prioritization in `governance.threat_mappings`.

---

## Versioning & feedback

This scale is normative for spec **v0.1.0**. The five level names are an ordered enum and are intended to be stable within a major spec version; refinements to definitions, the matrix, and the field-requirement table are expected as the scale meets real agents. Issues and proposals welcome in the repository.
