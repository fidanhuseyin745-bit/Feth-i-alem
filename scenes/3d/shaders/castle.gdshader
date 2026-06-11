shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// Genshin Impact tarzı kale shader'ı
uniform vec3 stone_color : source_color = vec3(0.7, 0.65, 0.6);
uniform vec3 stone_dark : source_color = vec3(0.4, 0.35, 0.3);
uniform vec3 gold_accent : source_color = vec3(1.0, 0.85, 0.2);
uniform float roughness : hint_range(0.0, 1.0) = 0.6;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float time : hint_range(0.0, 100.0) = 0.0;
uniform float glow_intensity = 0.3;

varying vec3 world_normal;
varying vec3 world_pos;
varying vec2 uv_coord;

// Stone noise
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

float voronoi(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float min_dist = 1.0;
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            vec2 neighbor = vec2(float(x), float(y));
            vec2 point = hash(i + neighbor) * vec2(1.0);
            float d = length(neighbor + point - f);
            min_dist = min(min_dist, d);
        }
    }
    return min_dist;
}

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
    uv_coord = UV;
}

void fragment() {
    // Stone texture
    float stone_n = noise(uv_coord * 8.0);
    float stone_v = voronoi(uv_coord * 4.0);
    float cracks = smoothstep(0.3, 0.5, stone_v);
    
    vec3 stone = mix(stone_color, stone_dark, stone_n * 0.3);
    stone = mix(stone, stone_dark * 0.5, cracks * 0.4);
    
    // Gold accents on edges
    float edge = pow(1.0 - abs(dot(world_normal, vec3(0.0, 1.0, 0.0))), 4.0);
    float gold_lines = step(0.95, fract(uv_coord.y * 10.0));
    vec3 gold = mix(stone, gold_accent, edge * gold_lines);
    
    // Bump mapping simulation
    float bump = noise(uv_coord * 20.0) * 0.1;
    stone *= 1.0 - bump;
    
    // Glow effect
    float glow = sin(time * 0.5 + uv_coord.y * 5.0) * 0.5 + 0.5;
    vec3 emission = gold_accent * glow * glow_intensity * gold_lines;
    
    ALBEDO = gold;
    ROUGHNESS = roughness;
    METALLIC = metallic + edge * 0.3;
    EMISSION = emission;
    
    // Rim light
    float rim = pow(1.0 - abs(dot(world_normal, normalize(vec3(0.0, 1.0, -1.0)))), 3.0);
    ALBEDO += gold_accent * rim * 0.2;
}