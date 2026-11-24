#!/usr/bin/env bash
# Runs the versioned test suite (GUT) headless. Usage: tools/run_tests.sh [script-path-or-filter]
# Exit code is non-zero on any failed test, SCRIPT ERROR or Parse Error.
set -u
cd "$(dirname "$0")/.."

OUT="$(mktemp)"
trap 'rm -f "$OUT"' EXIT

godot --headless --path game --import >"$OUT" 2>&1
if grep -qE "SCRIPT ERROR|Parse Error" "$OUT"; then
	cat "$OUT"
	echo "run_tests: errors during import" >&2
	exit 1
fi

ARGS=(-gconfig=res://.gutconfig.json)
if [ $# -gt 0 ]; then
	ARGS+=("-gselect=$1")
fi

godot --headless --path game -s addons/gut/gut_cmdln.gd "${ARGS[@]}" 2>&1 | tee "$OUT"
status=${PIPESTATUS[0]}

if grep -qE "SCRIPT ERROR|Parse Error" "$OUT"; then
	echo "run_tests: SCRIPT ERROR or Parse Error found" >&2
	exit 1
fi
if ! grep -q "All tests passed" "$OUT" && [ "$status" -eq 0 ]; then
	echo "run_tests: no 'All tests passed' line (no tests run?)" >&2
	exit 1
fi
exit "$status"
