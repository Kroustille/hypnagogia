// White flash of an entity hit by a shot. flash = 0: texture unchanged; flash = 1: pure white silhouette.
// The texture alpha is kept, so only the visible pixels turn white. modulate cannot go brighter than white.
shader_type canvas_item;

uniform float flash : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	// In fragment(), COLOR already holds texture * vertex color (modulate) unless it is overwritten.
	COLOR.rgb = mix(COLOR.rgb, vec3(1.0), flash);
}
