#!/usr/bin/env bash
# Runs the versioned test suite (GUT) headless; tests never touch the player's user:// data.
# Usage: tools/run_tests.sh [path/to/test_file.gd | path/to/dir/ | script-name-filter]
# Env: TEST_TIMEOUT (seconds, default 300).
# Exit code is non-zero on any failed test, SCRIPT ERROR, Parse Error or timeout.
set -u
cd "$(dirname "$0")/.."

OUT="$(mktemp)"
DATA_DIR="$(mktemp -d)"
export XDG_DATA_HOME="$DATA_DIR"
trap 'rm -f "$OUT"; rm -rf "$DATA_DIR"' EXIT

# On a fresh clone the first import prints resource errors (fonts, translations
# not imported yet): run it once uncontrolled, then check the second one.
if [ ! -d game/.godot ]; then
	godot --headless --path game --import >/dev/null 2>&1
fi

godot --headless --path game --import >"$OUT" 2>&1
if grep -qE "SCRIPT ERROR|Parse Error" "$OUT"; then
	cat "$OUT"
	echo "run_tests: errors during import" >&2
	exit 1
fi

ARGS=(-gconfig=res://.gutconfig.json)
if [ $# -gt 0 ]; then
	case "$1" in
		*.gd) ARGS+=("-gtest=res://${1#game/}" "-gselect=$(basename "$1")") ;;
		*/) ARGS+=("-gdir=res://${1#game/}") ;;
		*) ARGS+=("-gselect=$1") ;;
	esac
fi

timeout --kill-after=10 "${TEST_TIMEOUT:-300}" godot --headless --path game -s addons/gut/gut_cmdln.gd "${ARGS[@]}" 2>&1 | tee "$OUT"
status=${PIPESTATUS[0]}
if [ "$status" -eq 124 ] || [ "$status" -eq 137 ]; then
	echo "run_tests: timed out" >&2
	exit 1
fi

if grep -qE "SCRIPT ERROR|Parse Error" "$OUT"; then
	echo "run_tests: SCRIPT ERROR or Parse Error found" >&2
	exit 1
fi
if ! grep -q "All tests passed" "$OUT" && [ "$status" -eq 0 ]; then
	echo "run_tests: no 'All tests passed' line (no tests run?)" >&2
	exit 1
fi
exit "$status"
