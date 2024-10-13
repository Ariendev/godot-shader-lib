shader_type spatial;
render_mode diffuse_toon, specular_toon;

group_uniforms diffuse;
uniform sampler2D main_tex : hint_default_white, filter_nearest_mipmap;
uniform vec3 tint : source_color = vec3(1.0);

group_uniforms normal;
uniform sampler2D normal_tex : hint_normal, filter_nearest_mipmap;
uniform float normal_strength : hint_range(-15.0, 15.0, 0.1) = 1.0;

group_uniforms sampling;
uniform vec2 tiling = vec2(1.0);
uniform vec2 offset = vec2(0.0);

group_uniforms shadow;
uniform float shadow_offset : hint_range(-1.0, 1.0, 0.001) = 0.075;
uniform float shadow_width : hint_range(0.0, 5.0, 0.01) = 2.5;
uniform vec3 shadow_color : source_color = vec3(0.66);
uniform int steps = 2;

group_uniforms specular;
uniform bool specular_enabled = true;
uniform float specular_size : hint_range(0.0, 0.5) = 0.002;
uniform float specular_width : hint_range(0.0, 0.5) = 0.01;
uniform float specular_strength : hint_range(0.0, 0.25) = 0.075;

group_uniforms rim;
uniform bool rim_enabled = true;
uniform float rim_size : hint_range(0,1) = 0.25;
uniform float rim_smoothness : hint_range(0.0,0.5) = 0.01;
uniform vec3 rim_color : source_color = vec3(0.66);


void fragment() {
	vec2 uv = UV * tiling + offset;
	ALBEDO = pow(texture(main_tex, uv).rgb * tint, vec3(1.25));
	NORMAL_MAP = texture(normal_tex, uv).xyz;
	NORMAL_MAP_DEPTH = normal_strength;
}

void light() {

	// shadow
	float ndl = (clamp(dot(LIGHT, NORMAL), 0.0 ,1.0)) * ATTENUATION;
	ndl = (ndl * shadow_width) + shadow_offset;
	ndl = clamp(ndl, 0.0, 1.0);
	ndl = round(ndl * float(steps)) / float(steps);

	float ndla = clamp(dot(LIGHT, NORMAL), 0.0 ,1.0);
	ndla = (ndla * shadow_width) + shadow_offset;
	ndla = clamp(ndla, 0.0, 1.0);
	ndla = round(ndla * float(steps)) / float(steps);
	
	// specular
	vec3 specular = vec3(0.0);
	if (specular_enabled) {
		vec3 vl = normalize(VIEW + LIGHT);
		float ndvl = max(0.0, dot(NORMAL, vl));
		float specular_intensity = pow(ndvl, 1./specular_size);
		specular = vec3(smoothstep(0.5 - specular_width, 0.5 + specular_width, specular_intensity));
		specular = round(specular * float(steps)) / float(steps);
		specular = mix(vec3(0.0), specular * specular_strength * LIGHT_COLOR, ndl);
	}
	
	
	// rim
	vec3 rim = vec3(0.0);
	if (rim_enabled) {
		float vdn = 1.-dot(VIEW, NORMAL);
		float rim_value = vdn * ndl;
		rim = vec3(smoothstep((1.-rim_size) - rim_smoothness, (1.-rim_size) + rim_smoothness, rim_value));
		rim = round(rim * float(steps)) / float(steps);
		rim *= rim_color;
	}
	
	// combine everything
	vec3 stepped_light_color = LIGHT_COLOR * round(ATTENUATION * float(steps)) / float(steps);
	vec3 final = ndl * stepped_light_color * ALBEDO;
	final = clamp(final, 0.0, 1.0) + (specular+(rim*stepped_light_color));
	DIFFUSE_LIGHT += (final);
}
