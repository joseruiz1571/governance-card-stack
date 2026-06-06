# Governance Card Stack — Agent Card CI gate
#
# Lints an Agent Card for governance gaps that JSON Schema can't express
# (staleness, risk-tier obligations, dangling threats, autonomy coherence).
# Run AFTER schema validation — this ordering is load-bearing, not a
# convention. The schema is what guarantees `classification` and `risk_tier`
# exist and are well-typed; rules below assume that guarantee and will degrade
# silently (deny goes undefined, not true) on a card that skipped it. Chain
# the two with `&&` so a schema failure blocks the gate from running at all —
# never run conftest on a card that hasn't passed check-jsonschema first:
#
#   check-jsonschema --schemafile schemas/agent-card.schema.json card.json && \
#     conftest test card.json --policy policies/ --all-namespaces
#
# GitHub Actions (sketch):
#   - run: |
#       check-jsonschema --schemafile schemas/agent-card.schema.json "$CARD" && \
#         conftest test "$CARD" --policy policies/ --all-namespaces
# CI fails on any `deny`; `warn` prints but does not fail.

package governance.agent_card

import rego.v1

high_risk := {"critical", "high"}
supported_versions := {"0.1.0"}
high_autonomy := {"autonomous", "autonomous_bounded"}
low_autonomy := {"assistive", "supervised"}

# ---- helpers ----
card_is_agent if input.card_type == "agent"

spec_supported if input.spec_version in supported_versions

kill_switch_available if input.escalation.kill_switch.available == true

tool_requires_approval(t) if t.requires_approval == true

has_autonomy_exception if {
	some p in object.get(input, "props", [])
	p.name == "autonomy-exception"
}

# ---- deny (fails the build) ----

deny contains msg if {
	not card_is_agent
	msg := sprintf("card_type must be 'agent' (got '%v').", [object.get(input, "card_type", "<missing>")])
}

deny contains msg if {
	not spec_supported
	msg := sprintf("spec_version '%v' is not supported by this gate (supported: %v).", [object.get(input, "spec_version", "<missing>"), supported_versions])
}

# next_review must be present and a valid YYYY-MM-DD date. Without this check,
# a missing or malformed value makes time.parse_ns undefined (not false), so
# the staleness rule below would silently never fire — deleting one optional
# field would quietly disable the gate's headline check.
deny contains msg if {
	review := object.get(object.get(input, "classification", {}), "next_review", "")
	not regex.match(`^[0-9]{4}-[0-9]{2}-[0-9]{2}$`, review)
	msg := sprintf("classification.next_review is missing or not a valid YYYY-MM-DD date (got '%v') — staleness cannot be verified.", [review])
}

# A Card with a parseable next_review must be current.
deny contains msg if {
	due := time.parse_ns("2006-01-02", input.classification.next_review)
	due < time.now_ns()
	msg := sprintf("Agent Card is stale: next_review %v is in the past — re-review and update.", [input.classification.next_review])
}

# HIGH/CRITICAL agents must be bounded, killable, and evidenced.
deny contains msg if {
	input.classification.risk_tier in high_risk
	count(object.get(input, "decision_boundaries", [])) == 0
	msg := sprintf("risk_tier '%v' requires at least one decision_boundary.", [input.classification.risk_tier])
}

deny contains msg if {
	input.classification.risk_tier in high_risk
	not kill_switch_available
	msg := "HIGH/CRITICAL agents must declare an available kill switch (escalation.kill_switch.available = true)."
}

deny contains msg if {
	input.classification.risk_tier in high_risk
	count(object.get(input, "evidence", [])) == 0
	msg := sprintf("risk_tier '%v' requires at least one linked evidence artifact.", [input.classification.risk_tier])
}

# Every declared threat must map to a mitigation (no dangling threats).
deny contains msg if {
	some t in object.get(input.governance, "threat_mappings", [])
	count(object.get(t, "mitigated_by", [])) == 0
	msg := sprintf("Threat '%v' (%v) has no mitigation in mitigated_by.", [t.threat_id, t.taxonomy])
}

# Controls claimed 'implemented' must cite evidence.
deny contains msg if {
	some c in input.governance.control_mappings
	c.status == "implemented"
	count(object.get(c, "evidence_refs", [])) == 0
	msg := sprintf("Control %v (%v) claims 'implemented' but cites no evidence_refs.", [c.control_id, c.framework])
}

# Irreversible write tools must require approval.
deny contains msg if {
	some tool in object.get(input, "tools", [])
	tool.data_access in {"write", "read_write"}
	tool.reversibility == "irreversible"
	not tool_requires_approval(tool)
	msg := sprintf("Tool '%v' performs irreversible writes and must set requires_approval = true.", [tool.tool_id])
}

# Autonomy / oversight coherence (see docs/autonomy-levels.md).
deny contains msg if {
	input.autonomy.autonomy_level in high_autonomy
	input.autonomy.human_oversight == "human_in_the_loop"
	msg := sprintf("Incoherent autonomy: '%v' cannot run human_in_the_loop. See docs/autonomy-levels.md.", [input.autonomy.autonomy_level])
}

deny contains msg if {
	input.autonomy.autonomy_level in low_autonomy
	input.autonomy.human_oversight == "human_out_of_the_loop"
	msg := sprintf("Incoherent autonomy: '%v' cannot run human_out_of_the_loop. See docs/autonomy-levels.md.", [input.autonomy.autonomy_level])
}

# Full autonomy requires documented risk acceptance.
deny contains msg if {
	input.autonomy.autonomy_level == "autonomous"
	not has_autonomy_exception
	msg := "autonomy_level 'autonomous' requires documented risk acceptance (a props entry with name = 'autonomy-exception')."
}

# ---- warn (prints, does not fail) ----

warn contains msg if {
	due := time.parse_ns("2006-01-02", input.classification.next_review)
	due >= time.now_ns()
	due < time.now_ns() + ((14 * 24 * 60 * 60) * 1000000000)
	msg := sprintf("Agent Card review is due within 14 days (next_review %v).", [input.classification.next_review])
}

warn contains msg if {
	some e in object.get(input, "evidence", [])
	not e.retention_until
	msg := sprintf("Evidence '%v' has no retention_until; the tamper-evidence window is unbounded.", [object.get(e, "description", "<unnamed>")])
}

warn contains msg if {
	input.autonomy.autonomy_level == "autonomous_bounded"
	msg := "autonomy_level 'autonomous_bounded' runs without per-action oversight; confirm boundaries and monitoring are sufficient."
}
