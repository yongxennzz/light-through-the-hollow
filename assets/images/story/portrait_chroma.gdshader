shader_type canvas_item;
varying vec4 tint;
void vertex() {
	tint = COLOR;
}
// These generated RGB portraits use a green backing, not an alpha channel.
// The blue-channel condition protects the witch's turquoise hair.
void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	float dominance = pixel.g - max(pixel.r, pixel.b);
	float key = smoothstep(0.28, 0.60, dominance);
	pixel.a *= 1.0 - key;
	COLOR = pixel * tint;
}
