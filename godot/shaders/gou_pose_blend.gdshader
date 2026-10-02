shader_type canvas_item;
uniform vec2 previous_shift = vec2(0.0);
uniform float pose_blend : hint_range(0.0, 1.0) = 1.0;
varying vec4 pose_modulate;
void vertex() { pose_modulate = COLOR; }
void fragment() {
    vec4 current_pose = texture(TEXTURE, UV);
    vec4 previous_pose = texture(TEXTURE, UV + previous_shift);
    float alpha = mix(previous_pose.a, current_pose.a, pose_blend);
    vec3 premultiplied = mix(previous_pose.rgb*previous_pose.a, current_pose.rgb*current_pose.a, pose_blend);
    vec3 rgb = premultiplied / max(alpha, 0.00001);
    COLOR = pose_modulate * vec4(rgb, alpha);
}
