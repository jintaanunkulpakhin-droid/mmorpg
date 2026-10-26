// Toon shader for characters, clothes, buildings and props.
// Set "albedo" to pick the colour. Turn on "use_checker" for tiled floors.
shader_type spatial;

#include "res://shaders/toon_light.gdshaderinc"

uniform vec4 albedo : source_color = vec4(1.0);
uniform bool use_checker = false;
uniform vec4 checker_color : source_color = vec4(1.0);
uniform float checker_size = 1.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 col = albedo.rgb;
	if (use_checker) {
		vec2 cell = floor(world_pos.xz / checker_size);
		if (mod(cell.x + cell.y, 2.0) > 0.5) {
			col = checker_color.rgb;
		}
	}
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
