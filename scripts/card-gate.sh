#!/usr/bin/env bash
#
# Card gate — every Card in the repo must be schema-valid, then policy-clean.
#
# The ordering is load-bearing, and policies/agent_card.rego says why in its
# own header: the Rego rules assume the schema has already guaranteed that
# `classification` and `risk_tier` exist and are well-typed. On a card that
# skipped validation those rules degrade silently — `deny` goes undefined
# rather than true — so a malformed card would sail through. Schema first,
# and a schema failure stops that card before the policy ever runs.
#
# Fail-closed by construction:
#   - zero Cards found            -> fail (a gate that passes on an empty set
#                                    is not a gate)
#   - card_type missing           -> fail (cannot choose a schema)
#   - no schema for that type     -> fail (cannot validate)
#   - schema invalid              -> fail, and skip the policy for that card
#   - policy package missing      -> fail (`opa eval --fail`, so renaming the
#                                    package breaks the build instead of
#                                    quietly emptying `deny`)
#   - any `deny`                  -> fail
#   - any `warn`                  -> printed, does not fail
#
# Run it locally exactly as CI does:
#   ./scripts/card-gate.sh
#
# Requires: opa, check-jsonschema, jq.

set -euo pipefail

cd "$(dirname "$0")/.."

mapfile -t cards < <(find . -name '*.card.json' -not -path './.git/*' | sort)

if [ "${#cards[@]}" -eq 0 ]; then
	echo "FAIL: no *.card.json found in the repo — the gate has nothing to check."
	echo "      Refusing to pass: a gate that passes on an empty set is not a gate."
	exit 1
fi

echo "Found ${#cards[@]} Card(s)."
status=0

for card in "${cards[@]}"; do
	echo "────────────────────────────────────────────────────────────"
	echo "Card: ${card#./}"

	if ! card_type=$(jq -er '.card_type' "$card" 2>/dev/null); then
		echo "  FAIL: card_type is missing or not a string — cannot choose a schema."
		status=1
		continue
	fi

	schema="schemas/${card_type}-card.schema.json"
	if [ ! -f "$schema" ]; then
		echo "  FAIL: card_type '${card_type}' has no schema at ${schema}."
		status=1
		continue
	fi

	echo "  card_type: ${card_type}"
	echo "  schema:    ${schema}"

	if ! check-jsonschema --schemafile "$schema" "$card"; then
		echo "  FAIL: schema validation failed — skipping the policy for this card,"
		echo "        because the policy's rules assume a schema-valid input."
		status=1
		continue
	fi

	# governance.agent_card is written for agent Cards. Running it against a
	# model or system Card would deny on card_type and say nothing useful, so
	# those are schema-checked only until their own policies exist.
	if [ "$card_type" != "agent" ]; then
		echo "  policy:    none yet for '${card_type}' Cards — schema-checked only."
		continue
	fi

	echo "  policy:    governance.agent_card"

	result=$(opa eval --fail --format json \
		--data policies/agent_card.rego \
		--input "$card" \
		'data.governance.agent_card')

	warn=$(jq -r '.result[0].expressions[0].value.warn // [] | .[]' <<<"$result")
	deny=$(jq -r '.result[0].expressions[0].value.deny // [] | .[]' <<<"$result")

	if [ -n "$warn" ]; then
		while IFS= read -r m; do echo "  warn: ${m}"; done <<<"$warn"
	fi

	if [ -n "$deny" ]; then
		while IFS= read -r m; do echo "  DENY: ${m}"; done <<<"$deny"
		status=1
	else
		echo "  PASS: no denials."
	fi
done

echo "────────────────────────────────────────────────────────────"
if [ "$status" -ne 0 ]; then
	echo "Card gate FAILED — see DENY lines above."
else
	echo "Card gate passed: ${#cards[@]} Card(s) valid and current."
fi
exit "$status"
