#!/usr/bin/env bash
# Builds a room scene from its ASCII source. Usage: tools/build_room.sh art_source/rooms/<name>.txt [output.tscn]
# The scene lands in game/rooms/pool/<phase>/<name>.tscn (phase = first word of the name) unless an output is given.
set -u
if [ $# -lt 1 ]; then
	echo "usage: tools/build_room.sh <source.txt> [output.tscn]" >&2
	exit 2
fi
cd "$(dirname "$0")/.."

SOURCE="$(realpath "$1")"
OUTPUT=""
if [ $# -gt 1 ]; then
	OUTPUT="$(realpath -m "$2")"
fi

OUT="$(mktemp)"
trap 'rm -f "$OUT"' EXIT

timeout 120 godot --headless --path game --scene res://rooms/validator/room_builder.tscn -- "$SOURCE" $OUTPUT >"$OUT" 2>&1
status=$?
grep -vE "^Godot Engine|^$" "$OUT"
if grep -qE "SCRIPT ERROR|Parse Error" "$OUT"; then
	echo "build_room: SCRIPT ERROR or Parse Error found" >&2
	exit 1
fi
exit "$status"
