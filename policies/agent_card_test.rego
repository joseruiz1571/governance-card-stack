# Tests for the Agent Card gate. Run: opa test policies/ -v
package governance.agent_card

import rego.v1

# A minimal, coherent, low-risk Card (far-future review so the test never rots).
valid_card := {
	"spec_version": "0.1.0",
	"card_type": "agent",
	"classification": {"risk_tier": "low", "next_review": "2099-01-01"},
	"autonomy": {"autonomy_level": "assistive", "human_oversight": "human_in_the_loop"},
	"governance": {"frameworks": ["NIST AI RMF 1.0"], "control_mappings": []},
}

test_valid_card_has_no_denials if {
	count(deny) == 0 with input as valid_card
}

# A missing next_review must be denied — not silently pass. (time.parse_ns is
# undefined, not false, on a missing field, so the staleness rule alone would
# never fire here; this is the rule that closes that gap.)
test_missing_next_review_denied if {
	card := {
		"spec_version": "0.1.0",
		"card_type": "agent",
		"classification": {"risk_tier": "low"},
		"autonomy": {"autonomy_level": "assistive", "human_oversight": "human_in_the_loop"},
		"governance": {"frameworks": ["NIST AI RMF 1.0"], "control_mappings": []},
	}
	some m in deny with input as card
	contains(m, "next_review")
}

# A malformed next_review (not YYYY-MM-DD) must be denied — not silently pass.
test_malformed_next_review_denied if {
	card := {
		"spec_version": "0.1.0",
		"card_type": "agent",
		"classification": {"risk_tier": "low", "next_review": "soon"},
		"autonomy": {"autonomy_level": "assistive", "human_oversight": "human_in_the_loop"},
		"governance": {"frameworks": ["NIST AI RMF 1.0"], "control_mappings": []},
	}
	some m in deny with input as card
	contains(m, "next_review")
}

# Stale review must be denied.
test_stale_review_denied if {
	stale := {
		"spec_version": "0.1.0",
		"card_type": "agent",
		"classification": {"risk_tier": "low", "next_review": "2000-01-01"},
		"autonomy": {"autonomy_level": "assistive", "human_oversight": "human_in_the_loop"},
		"governance": {"frameworks": ["NIST AI RMF 1.0"], "control_mappings": []},
	}
	some m in deny with input as stale
	contains(m, "stale")
}

# HIGH risk without a kill switch must be denied.
test_high_risk_requires_kill_switch if {
	card := {
		"spec_version": "0.1.0",
		"card_type": "agent",
		"classification": {"risk_tier": "high", "next_review": "2099-01-01"},
		"autonomy": {"autonomy_level": "delegated", "human_oversight": "human_on_the_loop"},
		"decision_boundaries": [{"id": "b1", "type": "limit", "description": "x", "on_breach": "escalate"}],
		"evidence": [{
			"uuid": "7b2c9e14-3a6d-4f81-9c0a-2e78a1b4c0d3",
			"description": "e",
			"href": "s3://x",
			"collected_at": "2026-01-01T00:00:00Z",
			"retention_until": "2027-01-01T00:00:00Z",
		}],
		"governance": {"frameworks": ["NIST AI RMF 1.0"], "control_mappings": []},
	}
	some m in deny with input as card
	contains(m, "kill switch")
}

# Incoherent autonomy (autonomous + in-the-loop) must be denied.
test_incoherent_autonomy_denied if {
	card := {
		"spec_version": "0.1.0",
		"card_type": "agent",
		"classification": {"risk_tier": "low", "next_review": "2099-01-01"},
		"autonomy": {"autonomy_level": "autonomous", "human_oversight": "human_in_the_loop"},
		"governance": {"frameworks": ["NIST AI RMF 1.0"], "control_mappings": []},
		"props": [{"name": "autonomy-exception", "value": "approved by CRO 2026-05"}],
	}
	some m in deny with input as card
	contains(m, "Incoherent autonomy")
}

# A coherent low-risk Card whose references all resolve. The three tests below
# each break one reference and expect a denial.
resolving_card := {
	"spec_version": "0.1.0",
	"card_type": "agent",
	"classification": {"risk_tier": "low", "next_review": "2099-01-01"},
	"autonomy": {"autonomy_level": "assistive", "human_oversight": "human_in_the_loop"},
	"tools": [{"tool_id": "t1", "name": "t", "data_access": "read", "threat_refs": ["LLM06"]}],
	"decision_boundaries": [{"id": "b1", "type": "limit", "description": "x", "on_breach": "escalate"}],
	"governance": {
		"frameworks": ["NIST AI RMF 1.0"],
		"control_mappings": [{
			"control_id": "MAP 1.1",
			"framework": "NIST AI RMF 1.0",
			"status": "implemented",
			"evidence_refs": ["7B2C9E14-3A6D-4F81-9C0A-2E78A1B4C0D3"],
		}],
		"threat_mappings": [{"threat_id": "LLM06", "taxonomy": "owasp-llm", "mitigated_by": ["b1", "MAP 1.1"]}],
	},
	"evidence": [{
		"uuid": "7b2c9e14-3a6d-4f81-9c0a-2e78a1b4c0d3",
		"description": "e",
		"href": "s3://x",
		"collected_at": "2026-01-01T00:00:00Z",
		"retention_until": "2027-01-01T00:00:00Z",
	}],
}

# References that resolve are accepted, and UUIDs match without regard to case.
test_resolving_references_have_no_denials if {
	count(deny) == 0 with input as resolving_card
}

# An evidence_ref that names no evidence[] item is a citation to nothing.
test_unresolved_evidence_ref_denied if {
	card := json.patch(resolving_card, [{
		"op": "replace",
		"path": "/governance/control_mappings/0/evidence_refs",
		"value": ["11111111-2222-4333-8444-555555555555"],
	}])
	some m in deny with input as card
	contains(m, "matches no evidence[] item")
}

# A mitigated_by entry must name a control_id or a decision_boundary id.
test_unresolved_mitigation_denied if {
	card := json.patch(resolving_card, [{
		"op": "replace",
		"path": "/governance/threat_mappings/0/mitigated_by",
		"value": ["no-such-boundary"],
	}])
	some m in deny with input as card
	contains(m, "matches no control_id or decision_boundary id")
}

# A tool's threat_refs entry must name a declared threat.
test_unresolved_threat_ref_denied if {
	card := json.patch(resolving_card, [{
		"op": "replace",
		"path": "/tools/0/threat_refs",
		"value": ["AML.T9999"],
	}])
	some m in deny with input as card
	contains(m, "matches no threat_mappings entry")
}
