// Shared cel (toon) lighting used by every toon shader in the game.
// Light is split into a lit band and a shadow band, and the shadow band is
// tinted warm (peach/plum) instead of going grey.

uniform vec4 shade_color : source_color = vec4(0.78, 0.6, 0.66, 1.0);
uniform float band_cut : hint_range(-1.0, 1.0) = 0.0;
uniform float band_soft : hint_range(0.0, 0.5) = 0.05;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.25;

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(band_cut - band_soft, band_cut + band_soft, ndl) * ATTENUATION;
	if (LIGHT_IS_DIRECTIONAL) {
		// The sun lights everything: lit side gets full colour, shadow side gets the warm tint.
		DIFFUSE_LIGHT += LIGHT_COLOR / PI * mix(shade_color.rgb, vec3(1.0), lit);
		// A thin bright edge on the lit side helps characters pop out of the background.
		float rim = smoothstep(0.62, 0.7, 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0));
		SPECULAR_LIGHT += LIGHT_COLOR / PI * rim * lit * rim_strength;
	} else {
		// Lamps and other small lights only add light where they reach.
		DIFFUSE_LIGHT += LIGHT_COLOR / PI * lit;
	}
}
