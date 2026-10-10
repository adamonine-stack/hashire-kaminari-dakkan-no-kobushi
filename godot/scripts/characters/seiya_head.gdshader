shader_type canvas_item;
uniform vec2 atlas_size;
uniform vec4 head_rect;
uniform vec2 head_anchor;
uniform vec2 neck_direction = vec2(0.0, -1.0);
uniform vec4 cell_rect;
uniform float head_scale = 1.0;
varying vec4 sprite_modulate;
bool shirt_pixel(vec4 c) {
    float lo = min(c.r, min(c.g, c.b));
    float hi = max(c.r, max(c.g, c.b));
    return c.a > 0.5 && lo > 0.12 && hi - lo < 0.10;
}
void vertex() { sprite_modulate = COLOR; }
void fragment() {
    vec2 p = UV * atlas_size;
    vec4 original = texture(TEXTURE, UV);
    if (p.x >= head_rect.x && p.x <= head_rect.x + head_rect.z && p.y >= head_rect.y && p.y <= head_rect.y + head_rect.w) {
        float neck_distance = dot(p - head_anchor, neck_direction);
        float neck_blend = smoothstep(0.0, 6.0, neck_distance);
        vec2 s = mix(vec2(1.0), vec2(head_scale), neck_blend);
        p = head_anchor + (p - head_anchor) / s;
        if (p.x < head_rect.x || p.x > head_rect.x + head_rect.z || p.y < head_rect.y || p.y > head_rect.y + head_rect.w) {
            COLOR = vec4(0.0);
        } else {
            COLOR = texture(TEXTURE, p / atlas_size) * sprite_modulate;
        }
        // The rectangular head ROI can overlap the white collar/shoulder.
        // Preserve those original neutral shirt pixels instead of
        // pulling them into the head or cutting a vertical transparent seam.
        // An isolated white eye/highlight is not a shirt patch.
        vec2 sample_step = vec2(2.0) / atlas_size;
        int neighbors = 0;
        if (shirt_pixel(texture(TEXTURE, UV + vec2(sample_step.x, 0.0)))) { neighbors += 1; }
        if (shirt_pixel(texture(TEXTURE, UV - vec2(sample_step.x, 0.0)))) { neighbors += 1; }
        if (shirt_pixel(texture(TEXTURE, UV + vec2(0.0, sample_step.y)))) { neighbors += 1; }
        if (shirt_pixel(texture(TEXTURE, UV - vec2(0.0, sample_step.y)))) { neighbors += 1; }
        if (shirt_pixel(original) && neighbors >= 3) {
            COLOR = original * sprite_modulate;
            p = UV * atlas_size;
        }
    } else {
        COLOR = texture(TEXTURE, p / atlas_size) * sprite_modulate;
    }
    if (p.x < cell_rect.x || p.y < cell_rect.y || p.x >= cell_rect.x + cell_rect.z || p.y >= cell_rect.y + cell_rect.w) {
        COLOR = vec4(0.0);
    }
}
