extends RefCounted

# Use the rendered idle body, excluding transparent atlas margins.
# Both endings share the same cast proportions and ground pivot.
const MIO_HEIGHT_RATIO := 0.97
const REN_HEIGHT_RATIO := 1.0

static func hero_height(actor: Node2D) -> float:
	var sprite: AnimatedSprite2D = actor.animated_character_sprite
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	var image := texture.get_image()
	if image.is_compressed(): image.decompress()
	var body := image.get_used_rect()
	return float(body.size.y) * absf(sprite.global_scale.y / actor.global_scale.y)

static func fit_rescued(sprite: Sprite2D, reference_height: float, ratio: float) -> void:
	var image := sprite.texture.get_image()
	if image.is_compressed(): image.decompress()
	var body := image.get_used_rect()
	sprite.region_enabled = true
	sprite.region_rect = body
	sprite.centered = false
	sprite.offset = Vector2(-body.size.x * 0.5, -body.size.y)
	sprite.scale = Vector2.ONE * reference_height * ratio / maxf(body.size.y, 1.0)
