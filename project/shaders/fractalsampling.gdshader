/*
	This shader is meant for landscapes and/or large objects that are far away.
	The tiling switches depending on the distance of the camera.
	originally made by https://github.com/zulubo
	ported to godot by https://github.com/Ariendev
*/

shader_type spatial;
render_mode cull_back;

group_uniforms Albedo;
uniform vec3 albedo_tint : source_color = vec3(1.);
uniform sampler2D albedo : filter_nearest_mipmap, hint_default_white;
uniform float albedo_scale : hint_range(0.0, 10.0, 0.5) = 1.;
uniform float albedo_min_scale = 1.;
uniform float albedo_min_distance = 10.;

group_uniforms NormalMap;
uniform sampler2D normal : filter_nearest_mipmap, hint_normal;
uniform float normal_strength : hint_range(-8.0, 8.0, 0.01) = 1.;

group_uniforms Metallic;
uniform bool enable_metallic = false;
uniform sampler2D metallic : filter_nearest_mipmap, hint_default_white;
uniform float metallic_strength : hint_range(.0, 1.0, 0.01) = 0.1;

group_uniforms Specular;
uniform bool enable_specular = false;
uniform sampler2D specular : filter_nearest_mipmap, hint_default_white;
uniform float specular_strength : hint_range(.0, 1.0, 0.01) = 0.02;

group_uniforms Roughness;
uniform bool enable_roughness = false;
uniform sampler2D roughness : filter_nearest_mipmap, hint_default_white;
uniform float roughness_strength : hint_range(.0, 1.0, 0.01) = 0.9;

varying vec3 world_pos;
varying vec3 camera_position_world;

void vertex() {
	world_pos = (vec4(VERTEX, 1.)*MODEL_MATRIX).xyz;
	camera_position_world = CAMERA_POSITION_WORLD;
}

vec3 fractal_texture(sampler2D tex, vec2 uv, float min_scale, float scale, float min_distance) {
	float d = max(min_scale, log2(distance(camera_position_world, world_pos)/min_distance));
	float stepd = floor(d);
	float pingpong = abs(mod(stepd, 2.));

	vec2 uvA = scale * world_pos.xz / exp2(stepd + pingpong);
	vec2 uvB = scale * world_pos.xz / exp2(stepd + (1. - pingpong));
	float blend_fac = fract(d);
	if (blend_fac >= pingpong) { blend_fac = blend_fac; }
	else { blend_fac = 1.-blend_fac; }

	vec3 texA = texture(tex, uvA).rgb;
	vec3 texB = texture(tex, uvB).rgb;

	return mix(texA, texB, blend_fac);
}

void fragment() {
	ALBEDO = fractal_texture(albedo, world_pos.xz, albedo_min_scale, albedo_scale, albedo_min_distance) * albedo_tint;
	
	vec3 n = fractal_texture(normal, world_pos.xz, albedo_min_scale, albedo_scale, albedo_min_distance);
	n.xy *= normal_strength;
	NORMAL_MAP = (n);

	if (enable_metallic) {
		METALLIC = fractal_texture(metallic, world_pos.xz, albedo_min_scale, albedo_scale, albedo_min_distance).x * metallic_strength;
	} else { METALLIC = metallic_strength; }

	if (enable_specular) { SPECULAR = fractal_texture(specular, world_pos.xz, albedo_min_scale, albedo_scale, albedo_min_distance).x * specular_strength; }
	else { SPECULAR = specular_strength; }

	if (enable_roughness) { ROUGHNESS = fractal_texture(roughness, world_pos.xz, albedo_min_scale, albedo_scale, albedo_min_distance).x * roughness_strength;
	} else { ROUGHNESS = roughness_strength; }
}
