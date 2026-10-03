shader_type canvas_item;
uniform vec2 atlas_size;
uniform vec4 head_rect;
uniform vec2 head_anchor;
uniform vec2 neck_direction = vec2(0.0, -1.0);
uniform vec4 cell_rect;
uniform float head_scale = 1.0;
varying vec4 sprite_modulate;
void vertex() { sprite_modulate = COLOR; }
void fragment() {
    vec2 p = UV * atlas_size;
    if (p.x >= head_rect.x && p.x <= head_rect.x + head_rect.z && p.y >= head_rect.y && p.y <= head_rect.y + head_rect.w) {
        float neck_blend = smoothstep(0.0, 6.0, dot(p - head_anchor, neck_direction));
        vec2 s = mix(vec2(1.0), vec2(head_scale), neck_blend);
        p = head_anchor + (p - head_anchor) / s;
        if (p.x < head_rect.x || p.x > head_rect.x + head_rect.z || p.y < head_rect.y || p.y > head_rect.y + head_rect.w) {
            COLOR = vec4(0.0);
        } else {
            COLOR = texture(TEXTURE, p / atlas_size) * sprite_modulate;
        }
    } else {
        COLOR = texture(TEXTURE, p / atlas_size) * sprite_modulate;
    }
    if (p.x < cell_rect.x || p.y < cell_rect.y || p.x >= cell_rect.x + cell_rect.z || p.y >= cell_rect.y + cell_rect.w) {
        COLOR = vec4(0.0);
    }
}
