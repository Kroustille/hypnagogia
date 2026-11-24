#!/usr/bin/env bash
# Validates every room scene under game/rooms/pool (dimensions, doors, markers). Usage: tools/validate_rooms.sh [res://dir]
# One line per problem; exit code non-zero when a room is invalid or when Godot reports a script error.
set -u
cd "$(dirname "$0")/.."

OUT="$(mktemp)"
DATA_DIR="$(mktemp -d)"
export XDG_DATA_HOME="$DATA_DIR" # the autoloads write telemetry to user://: keep it away from the player's data
trap 'rm -f "$OUT"; rm -rf "$DATA_DIR"' EXIT

ARGS=()
if [ $# -gt 0 ]; then
	ARGS=(-- "$1")
fi

timeout 120 godot --headless --path game --scene res://rooms/validator/validate_rooms.tscn "${ARGS[@]}" >"$OUT" 2>&1
status=$?
grep -vE "^Godot Engine|^$" "$OUT"
if grep -qE "SCRIPT ERROR|Parse Error" "$OUT"; then
	echo "validate_rooms: SCRIPT ERROR or Parse Error found" >&2
	exit 1
fi
exit "$status"
