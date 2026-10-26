// Darkens the edges of the screen so the middle (and the glowing spells)
// stand out, like the dark dungeon edges in the ECO reference.
shader_type canvas_item;

uniform float strength : hint_range(0.0, 1.0) = 0.75;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	p.x *= 1.25;
	float d = smoothstep(0.55, 1.45, length(p));
	COLOR = vec4(0.0, 0.0, 0.0, d * strength);
}
