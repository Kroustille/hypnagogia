class_name RunRng
extends RefCounted
## The random streams of one run (architecture D8). One run seed, and one named stream per use (combat, cosmetic, ...),
## each seeded from (run seed, stream name, floor index): a stream never disturbs another, and the same seed with the
## same actions replays the same draws. Game code never uses the global RNG.
## The seed is 40 bits, shown as 8 Crockford base32 characters (short enough to type).

const SEED_BITS: int = 40
const SEED_BYTES: int = 5
const CODE_LENGTH: int = 8
const BITS_PER_CHAR: int = 5
## Crockford base32 alphabet: no I, L, O or U.
const ALPHABET: String = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"

## Names of the streams (architecture D8): one per use, so that one never disturbs another.
const LAYOUT: StringName = &"layout"
const ROOMS: StringName = &"rooms"
const TREASURE: StringName = &"treasure"
const SHOP: StringName = &"shop"
const DROPS: StringName = &"drops"
const COMBAT: StringName = &"combat"
const COSMETIC: StringName = &"cosmetic"
## The attacks of the bosses (story 6.1): one stream per floor, never shared with combat or drops.
const BOSS: StringName = &"boss"

var run_seed: int = 0
var _streams: Dictionary = {}


func _init(seed_value: int = 0) -> void:
	run_seed = seed_value & ((1 << SEED_BITS) - 1)


## A fresh run seed, drawn without the global RNG.
static func draw_seed() -> int:
	var bytes: PackedByteArray = Crypto.new().generate_random_bytes(SEED_BYTES)
	var value: int = 0
	for byte: int in bytes:
		value = (value << 8) | byte
	return value


## The stream called name for this floor, created on first use and kept: later calls continue the same sequence.
func stream(stream_name: StringName, floor_index: int = 0) -> RandomNumberGenerator:
	var cache_key: String = "%s:%d" % [stream_name, floor_index]
	if _streams.has(cache_key):
		return _streams[cache_key]
	var generator: RandomNumberGenerator = RandomNumberGenerator.new()
	var digest: PackedByteArray = ("%d:%s:%d" % [run_seed, stream_name, floor_index]).sha256_buffer()
	generator.seed = digest.decode_s64(0) # assigning the seed also resets the state
	_streams[cache_key] = generator
	return generator


## The seed as 8 characters (Crockford base32), most significant first.
func seed_code() -> String:
	var code: String = ""
	for index: int in range(CODE_LENGTH - 1, -1, -1):
		code += ALPHABET[(run_seed >> (index * BITS_PER_CHAR)) & 31]
	return code


## The seed of a code typed by the player (case ignored, spaces and dashes ignored, I and L read as 1, O as 0). -1 when the code is invalid.
static func code_to_seed(code: String) -> int:
	var clean: String = code.strip_edges().to_upper().replace(" ", "").replace("-", "").replace("\t", "").replace("\n", "").replace("I", "1").replace("L", "1").replace("O", "0")
	if clean.length() != CODE_LENGTH:
		return -1
	var value: int = 0
	for character: String in clean:
		var digit: int = ALPHABET.find(character)
		if digit < 0:
			return -1
		value = (value << BITS_PER_CHAR) | digit
	return value


## The state of every stream created so far, "name:floor" -> state as a decimal string. A state is a 64-bit integer: JSON
## writes numbers as floats and would lose the bits above 2^53, so it is kept as text. A stream never created has nothing to
## save: it starts from (seed, name, floor) like the first time.
func export_states() -> Dictionary:
	var states: Dictionary = {}
	for key: String in _streams:
		var generator: RandomNumberGenerator = _streams[key]
		states[key] = str(generator.state)
	return states


## Puts the streams back where export_states() left them (creating the ones that do not exist yet). Call it after the draws
## that depend on the seed alone (the floor): the saved states are later than those. Entries that are not a "name:floor"
## key with a decimal state are skipped. Returns how many streams were restored.
func restore_states(states: Dictionary) -> int:
	var restored: int = 0
	for key: Variant in states:
		var value: Variant = states[key]
		if typeof(key) != TYPE_STRING or typeof(value) != TYPE_STRING:
			continue
		var cache_key: String = key
		var text: String = value
		var split: int = cache_key.rfind(":")
		if split <= 0 or not text.is_valid_int() or not cache_key.substr(split + 1).is_valid_int():
			continue
		var generator: RandomNumberGenerator = stream(StringName(cache_key.substr(0, split)), cache_key.substr(split + 1).to_int())
		generator.state = text.to_int()
		restored += 1
	return restored


## True when states has the shape export_states() makes.
static func states_are_valid(states: Variant) -> bool:
	if typeof(states) != TYPE_DICTIONARY:
		return false
	var dict: Dictionary = states
	for key: Variant in dict:
		var value: Variant = dict[key]
		if typeof(key) != TYPE_STRING or typeof(value) != TYPE_STRING:
			return false
		var cache_key: String = key
		var text: String = value
		var split: int = cache_key.rfind(":")
		if split <= 0 or not text.is_valid_int() or not cache_key.substr(split + 1).is_valid_int():
			return false
	return true
