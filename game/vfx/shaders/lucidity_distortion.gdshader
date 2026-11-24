shader_type canvas_item;
// Lucidity distortion of the decor (story 3.8): copies what is already drawn (the decor, drawn at a lower z_index)
// with a horizontal wave and a chromatic aberration. Every shift is a whole number of pixels, nothing is blurred.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
// Amplitude of the wave and shift of the red and blue channels, in pixels.
uniform float wave_amount = 0.0;
uniform float aberration = 0.0;
// Seconds of game time, moves the wave.
uniform float time = 0.0;

const float ROW_FREQUENCY = 0.35;
const float WAVE_SPEED = 2.0;

void fragment() {
	float row = floor(FRAGCOORD.y);
	float wave_px = floor(sin(row * ROW_FREQUENCY + time * WAVE_SPEED) * wave_amount + 0.5);
	float aberration_px = floor(aberration + 0.5);
	vec2 base = SCREEN_UV + vec2(wave_px, 0.0) * SCREEN_PIXEL_SIZE;
	vec2 split = vec2(aberration_px, 0.0) * SCREEN_PIXEL_SIZE;
	float red = texture(screen_texture, base + split).r;
	float green = texture(screen_texture, base).g;
	float blue = texture(screen_texture, base - split).b;
	COLOR = vec4(red, green, blue, 1.0);
}
