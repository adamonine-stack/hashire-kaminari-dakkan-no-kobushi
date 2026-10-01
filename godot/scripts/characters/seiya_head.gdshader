shader_type canvas_item;
uniform vec2 atlas_size;
uniform vec4 head_rect;
uniform vec2 head_anchor;
uniform float head_scale = 1.0;
varying vec4 sprite_modulate;
void vertex() { sprite_modulate = COLOR; }
void fragment() {
    vec2 p = UV * atlas_size;
    if (p.x >= head_rect.x && p.x <= head_rect.x + head_rect.z && p.y >= head_rect.y && p.y <= head_rect.y + head_rect.w) {
        float neck_blend = 1.0 - smoothstep(head_anchor.y - 6.0, head_anchor.y, p.y);
        vec2 s = mix(vec2(1.0), vec2(head_scale), neck_blend);
        p = head_anchor + (p - head_anchor) / s;
    }
    COLOR = texture(TEXTURE, p / atlas_size) * sprite_modulate;
}
