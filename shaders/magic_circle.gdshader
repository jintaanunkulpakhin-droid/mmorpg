// A glowing magic circle drawn on a flat quad lying on the floor.
// Everything (rings, ticks, star) is drawn with maths, so there is no texture.
// "fade" goes 0 -> 1 -> 0 while the circle appears and disappears.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 color : source_color = vec4(0.3, 0.8, 1.0, 1.0);
uniform float fade = 1.0;
uniform float spin = 0.0;

float ring(float r, float radius, float width) {
	return 1.0 - smoothstep(0.0, width, abs(r - radius));
}

// One straight edge of the star: a line 0.4 away from the middle.
float star_line(vec2 p, float angle) {
	float d = abs(dot(p, vec2(cos(angle), sin(angle))) - 0.4);
	return 1.0 - smoothstep(0.0, 0.02, d);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = atan(p.y, p.x);

	float glow = 0.0;
	glow += ring(r, 0.95, 0.025) * 1.2;
	glow += ring(r, 0.80, 0.015);
	glow += ring(r, 0.42, 0.015) * 0.8;

	// Little ticks between the two outer rings, turning one way.
	float ticks = step(0.82, r) * step(r, 0.93) * step(0.75, fract((a + spin) * 24.0 / 6.2831));
	glow += ticks * 0.7;

	// A six-pointed star made from two triangles, turning the other way.
	float star = 0.0;
	star = max(star, star_line(p, spin * -0.6));
	star = max(star, star_line(p, spin * -0.6 + 1.0472));
	star = max(star, star_line(p, spin * -0.6 + 2.0944));
	star = max(star, star_line(p, spin * -0.6 + 3.1416));
	star = max(star, star_line(p, spin * -0.6 + 4.1888));
	star = max(star, star_line(p, spin * -0.6 + 5.2360));
	star *= step(r, 0.8);
	glow += star * 0.9;

	// Soft fill in the middle.
	glow += (1.0 - smoothstep(0.0, 1.0, r)) * 0.18;
	glow *= step(r, 1.0);

	ALBEDO = color.rgb * glow * 1.6;
	ALPHA = clamp(glow, 0.0, 1.0) * fade;
}
