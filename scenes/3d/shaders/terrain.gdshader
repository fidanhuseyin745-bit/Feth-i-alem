shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 albedo : source_color = vec3(0.5, 0.7, 0.3);
uniform vec3 albedo2 : source_color = vec3(0.4, 0.6, 0.2);
uniform vec3 detail_albedo : source_color = vec3(0.6, 0.8, 0.4);
uniform float roughness : hint_range(0.0, 1.0) = 0.8;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float detail_scale = 20.0;
uniform float uv_scale = 0.1;
uniform sampler2D noise_texture : filter_linear_mipmap, repeat_enable;

varying vec3 world_normal;
varying vec3 world_pos;
varying vec2 terrain_uv;

// FBM Noise
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 5; i++) {
        value += amplitude * noise(p);
        p *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
    terrain_uv = world_pos.xz * uv_scale;
}

void fragment() {
    // Çok katmanlı terrain
    float n1 = fbm(terrain_uv * 0.5);
    float n2 = fbm(terrain_uv * 2.0);
    float n3 = fbm(terrain_uv * 8.0);
    
    // Yükseklik bazlı renk
    float height = world_pos.y * 0.05 + 0.5;
    vec3 terrain_color = mix(albedo, albedo2, n1);
    terrain_color = mix(terrain_color, detail_albedo, n2 * 0.5);
    
    // Detay
    float detail = fbm(terrain_uv * detail_scale);
    terrain_color *= 0.8 + detail * 0.4;
    
    // Normals
    vec3 normal = world_normal;
    
    // Grass tint
    float grass = smoothstep(0.3, 0.7, n2);
    terrain_color = mix(terrain_color, vec3(0.3, 0.6, 0.2), grass * 0.3);
    
    // Wetness
    float wet = smoothstep(0.6, 0.9, n3);
    terrain_color *= 1.0 + wet * 0.1;
    
    ALBEDO = terrain_color;
    ROUGHNESS = roughness - wet * 0.2;
    METALLIC = metallic;
    
    // Subsurface scattering approximation
    float sss = pow(1.0 - abs(dot(normal, vec3(0.0, 1.0, 0.0))), 2.0) * 0.2;
    EMISSION = terrain_color * sss;
}