shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// Genshin Impact tarzı karakter shader'ı
uniform vec3 skin_color : source_color = vec3(0.9, 0.75, 0.65);
uniform vec3 cloth_color : source_color = vec3(0.2, 0.15, 0.4);
uniform vec3 cloth_accent : source_color = vec3(0.9, 0.7, 0.1);
uniform vec3 eye_color : source_color = vec3(0.2, 0.5, 0.9);
uniform float roughness : hint_range(0.0, 1.0) = 0.5;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float time : hint_range(0.0, 100.0) = 0.0;

varying vec3 world_normal;
varying vec3 world_pos;
varying vec2 uv_coord;
varying float vertex_height;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
    uv_coord = UV;
    vertex_height = VERTEX.y;
}

void fragment() {
    // Cloth pattern
    float cloth_n = sin(uv_coord.y * 20.0) * 0.5 + 0.5;
    vec3 cloth = mix(cloth_color, cloth_color * 1.2, cloth_n * 0.3);
    
    // Gold trim
    float trim = step(0.95, fract(uv_coord.y * 10.0));
    cloth = mix(cloth, cloth_accent, trim);
    
    // Skin areas (face, hands)
    float skin_mask = smoothstep(0.8, 1.0, uv_coord.y) * smoothstep(1.2, 1.0, uv_coord.y);
    
    // Eye glow
    float eye_glow = 0.0;
    if (uv_coord.x > 0.4 && uv_coord.x < 0.6 && uv_coord.y > 0.8 && uv_coord.y < 0.95) {
        float eye_n = sin(time * 2.0 + uv_coord.x * 10.0) * 0.5 + 0.5;
        eye_glow = eye_n * 0.5;
    }
    
    vec3 base_color = mix(cloth, skin_color, skin_mask);
    base_color += eye_color * eye_glow;
    
    // Subsurface scattering for skin
    float sss = pow(1.0 - abs(dot(world_normal, vec3(0.0, 1.0, 0.0))), 2.0) * skin_mask * 0.3;
    
    // Rim light (anime style)
    vec3 view_dir = normalize(vec3(0.0, 1.0, -1.0));
    float rim = pow(1.0 - abs(dot(world_normal, view_dir)), 3.0);
    base_color += cloth_accent * rim * 0.5;
    
    // Specular highlight
    vec3 light_dir = normalize(vec3(1.0, 1.0, 0.5));
    float spec = pow(max(dot(world_normal, light_dir), 0.0), 32.0);
    base_color += vec3(1.0) * spec * 0.3;
    
    ALBEDO = base_color;
    ROUGHNESS = roughness;
    METALLIC = metallic;
    EMISSION = eye_color * eye_glow;
}