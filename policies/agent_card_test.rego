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
