class_name Glide
extends RefCounted
## Pure geometry of the Glide power (story 3.4): where a teleport toward a target ends. No node, no state:
## the physics space and the body shape are passed in. Call from _physics_process only (consistent space state).

## Safety gap kept between the body and what the ray hit, in pixels.
const HIT_MARGIN: float = 1.0
## Step of the backward search for a free landing spot, in pixels.
const BACKOFF_STEP: float = 1.0


## Distance to travel, in pixels. Mouse: up to the cursor, capped. Stick (dead zone already removed by
## Input.get_vector, so its length goes from 0 at the dead zone to 1 at full tilt): from min_stick to max.
## Released stick (zero): min_stick.
static func distance_for(tuning: GlideTuning, from_stick: bool, stick: Vector2, cursor_offset: Vector2) -> float:
	var max_px: float = tuning.max_distance * Const.TILE_SIZE
	if not from_stick:
		return minf(cursor_offset.length(), max_px)
	var min_px: float = tuning.min_stick_distance * Const.TILE_SIZE
	if stick == Vector2.ZERO:
		return minf(min_px, max_px)
	return lerpf(min_px, max_px, clampf(stick.length(), 0.0, 1.0))


## Last free point on the line from origin along dir (unit), at most distance px away. The ray stops at walls,
## high obstacles, furniture and enemies; then the body is moved back until it overlaps no wall, obstacle (high or low) or
## enemy. Returns origin when nothing is free.
static func resolve_destination(
	space: PhysicsDirectSpaceState2D, origin: Vector2, dir: Vector2, distance: float, shape: Shape2D, exclude: Array[RID]
) -> Vector2:
	if distance <= 0.0 or dir == Vector2.ZERO:
		return origin
	var target: Vector2 = origin + dir * distance
	var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		origin, target, Const.LAYER_WALLS | Const.LAYER_HIGH_OBSTACLES | Const.LAYER_FURNITURE | Const.LAYER_ENEMIES, exclude
	)
	ray.collide_with_areas = false
	var hit: Dictionary = space.intersect_ray(ray)
	if not hit.is_empty():
		var half_diagonal: float = shape.get_rect().size.length() / 2.0
		var hit_position: Vector2 = hit["position"]
		target = hit_position - dir * (half_diagonal + HIT_MARGIN)
		if (target - origin).dot(dir) < 0.0:
			return origin
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.collision_mask = Const.LAYER_WALLS | Const.LAYER_HIGH_OBSTACLES | Const.LAYER_LOW_OBSTACLES | Const.LAYER_FURNITURE | Const.LAYER_ENEMIES
	query.exclude = exclude
	query.margin = 0.0
	var travelled: float = origin.distance_to(target)
	var steps: int = ceili(travelled / BACKOFF_STEP)
	for i: int in steps + 1:
		var candidate: Vector2 = target - dir * minf(i * BACKOFF_STEP, travelled)
		query.transform = Transform2D(0.0, candidate)
		if space.intersect_shape(query, 1).is_empty():
			return candidate
	return origin
