@abstract
class_name ChalkPatterns
## Pure geometry of the chalk attacks of the bosses: no node, no clock, no global RNG. Distances in tiles.

const EPSILON: float = 1e-6


## The chalks of one row, as Vector2(x, 0) measured from the left edge of a row width_tiles wide, the gap excluded.
## The chalks are spacing_tiles apart and centered in the width; a chalk is kept only when its whole disc is outside
## the gap (gap_tiles clear tiles centered on gap_center).
static func row(width_tiles: float, spacing_tiles: float, gap_center: float, gap_tiles: float, bullet_radius_tiles: float) -> Array[Vector2]:
	var found: Array[Vector2] = []
	if not (is_finite(width_tiles) and is_finite(spacing_tiles) and width_tiles > 0.0 and spacing_tiles > 0.0):
		return found
	var count: int = floori(width_tiles / spacing_tiles + EPSILON)
	var margin: float = (width_tiles - count * spacing_tiles) / 2.0
	var gap_start: float = gap_center - gap_tiles / 2.0
	var gap_end: float = gap_center + gap_tiles / 2.0
	for i: int in count:
		var x: float = margin + (i + 0.5) * spacing_tiles
		if x + bullet_radius_tiles <= gap_start + EPSILON or x - bullet_radius_tiles >= gap_end - EPSILON:
			found.append(Vector2(x, 0.0))
	return found


## The center of the next gap, from unit (a draw of the BOSS stream, 0 to 1): uniform in the width, or, after a previous gap
## (finite), at most max_shift_tiles from it. Always whole inside the width.
static func next_gap(unit: float, previous: float, width_tiles: float, gap_tiles: float, max_shift_tiles: float) -> float:
	var low: float = gap_tiles / 2.0
	var high: float = width_tiles - gap_tiles / 2.0
	if high < low:
		return width_tiles / 2.0
	if not is_finite(previous):
		return lerpf(low, high, unit)
	var from: float = maxf(low, previous - max_shift_tiles)
	var to: float = minf(high, previous + max_shift_tiles)
	if to < from:
		return clampf(previous, low, high)
	return lerpf(from, to, unit)
