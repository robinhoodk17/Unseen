shader_type spatial;

render_mode
    cull_disabled,
    unshaded,
    blend_mix;
uniform float effectStrength;
group_uniforms Speed_Lines;
uniform vec4 color1: source_color;
uniform vec4 color2: source_color;
uniform sampler2D noise_texture; // Our noise texture
uniform vec2 direction; // Direction of UV movement
uniform float speed : hint_range(0.0, 10.0); // Speed of UV movement



vec2 refract_uv(vec2 uv_coords, float _refraction_strength, vec3 surface_normal) {
    float refraction_intensity = _refraction_strength * 1.0;
    uv_coords += refraction_intensity * length(surface_normal) - refraction_intensity * 1.2;
    return uv_coords;
}

vec3 calculate_neon_effect(float value, vec3 base_color) {
    float ramp = clamp(value, 0.0, 1.0);
    vec3 neon_color = vec3(0.0);
    ramp = ramp * ramp;
    neon_color += pow(base_color, vec3(4.0)) * ramp;
    ramp = ramp * ramp;
    neon_color += base_color * ramp;
    ramp = ramp * ramp;
    neon_color += vec3(1.0) * ramp;
    return neon_color;
}



void fragment() {
    vec2 uv_movement = UV + direction.xy * TIME * speed;
    // Sample the noise texture with the moving UVs
    vec4 noise_color1 = texture(noise_texture, uv_movement);
    vec4 noise_color2 = texture(noise_texture, uv_movement + vec2(0.50));

    // Apply noise color to the fragment
    ALBEDO = calculate_neon_effect(0.50 + noise_color1.a, color1.rgb);
    ALBEDO += calculate_neon_effect(0.50 + noise_color2.a, color2.rgb);
	if (ALBEDO.r < 1.0)
	{
		ALPHA = 0.0;
	}
	else
	{
		ALPHA =  pow(effectStrength,3);
	}
}