#!/usr/bin/env bash
# Stability soak of milestone B (story 6.9): 20 whole nights in a row against the real game, headless and faster than
# real time (--fixed-fps 60). Looks for crashes, engine errors and leaks; it says nothing about balance.
# Not part of tools/run_tests.sh (about a minute or more): run it by hand, or from the orchestrator at the end of an epic.
# Env: SOAK_RUNS (default 20), SOAK_MAX_SECONDS (default 600, wall clock safety bound).
# The report goes to tools/soak-result.txt (not versioned). Exit code is non-zero on any failure.
# The save and telemetry folders are temporary: the player's own user data is never touched.
set -u
cd "$(dirname "$0")/.."

OUT="tools/soak-result.txt"
DATA_DIR="$(mktemp -d)"
export XDG_DATA_HOME="$DATA_DIR"
export SOAK_ISOLATED=1 # the runner refuses to run on the real user data
trap 'rm -rf "$DATA_DIR"' EXIT

if [ ! -d game/.godot ]; then
	godot --headless --path game --import >/dev/null 2>&1
fi
godot --headless --path game --import >/dev/null 2>&1

timeout --kill-after=10 "${SOAK_TIMEOUT:-900}" godot --headless --path game --fixed-fps 60 --scene res://debug/soak_runner.tscn 2>&1 | tee "$OUT"
status=${PIPESTATUS[0]}
if [ "$status" -eq 124 ] || [ "$status" -eq 137 ]; then
	echo "soak: timed out" >&2
	exit 1
fi
if grep -qE "SCRIPT ERROR|Parse Error|^ERROR:|USER ERROR|physics" "$OUT"; then
	echo "soak: engine or game errors found in the output" >&2
	grep -E "SCRIPT ERROR|Parse Error|^ERROR:|USER ERROR|physics" "$OUT" | head -20 >&2
	exit 1
fi
if ! grep -q "soak: PASSED" "$OUT"; then
	echo "soak: no PASSED line" >&2
	exit 1
fi
exit "$status"
