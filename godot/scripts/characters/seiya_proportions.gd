extends Node

## A local head transform on the original art; no new face or outfit is drawn.
## Cache per-frame hair landmarks so the same proportion follows every action.
const HEAD_SHADER = preload("res://scripts/characters/seiya_head.gdshader")
var sprite: AnimatedSprite2D
var definition: Resource
var material: ShaderMaterial
var head_anchor := Vector2.ZERO
var head_bounds := Rect2()
var cache := {}
var landmarks := {}

func setup(target: AnimatedSprite2D, data: Resource) -> void:
	sprite = target
	definition = data
	landmarks = JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/player03/animations/dark_seiya_v1/head_landmarks.json"))
	material = ShaderMaterial.new()
	material.shader = HEAD_SHADER
	material.set_shader_parameter("head_scale", data.head_scale)
	sprite.material = material
	sprite.frame_changed.connect(update_head)
	sprite.animation_changed.connect(update_head)
	update_head()

func update_head() -> void:
	if sprite.animation == &"": return
	var texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if texture == null: return
	var key := "%s:%s" % [sprite.animation, sprite.frame]
	if texture is AtlasTexture and not cache.has(key):
		var file: String = texture.atlas.resource_path
		var landmark_key := "%s/%s:%d:%d" % [file.get_base_dir().get_file(),file.get_file(),texture.region.position.x,texture.region.position.y]
		if landmarks.has(landmark_key):
			var r: Array = landmarks[landmark_key]
			cache[key] = Rect2(r[0],r[1],r[2],r[3])
	if not cache.has(key):
		var img: Image = texture.get_image()
		var low := Vector2i(img.get_width(), img.get_height())
		var high := Vector2i.ZERO
		var mask := PackedByteArray()
		mask.resize(img.get_width()*img.get_height())
		# Saturated golden hair is distinct from the neutral beige trousers.
		for y in range(img.get_height()):
			for x in range(img.get_width()):
				var c := img.get_pixel(x,y)
				if c.a > 0.8 and c.r > 0.58 and c.g > 0.36 and c.b < c.r * 0.51 and c.g < c.r * 0.91:
					mask[y*img.get_width()+x] = 1
		var best_y := img.get_height()
		for index in range(mask.size()):
			if mask[index] != 1: continue
			var queue: Array[int] = [index]
			mask[index] = 2
			var a := Vector2i(img.get_width(),img.get_height())
			var b := Vector2i.ZERO
			var cursor := 0
			while cursor < queue.size():
				var n: int = queue[cursor]
				cursor += 1
				var x := n % img.get_width()
				var y := n / img.get_width()
				a = Vector2i(mini(a.x,x),mini(a.y,y))
				b = Vector2i(maxi(b.x,x),maxi(b.y,y))
				for v in [n-1 if x>0 else -1,n+1 if x<img.get_width()-1 else -1,n-img.get_width(),n+img.get_width()]:
					if v>=0 and v<mask.size() and mask[v]==1:
						mask[v]=2
						queue.append(v)
			if queue.size()>40 and b.y-a.y<65 and b.x-a.x>12 and a.y<best_y:
				low=a
				high=b
				best_y=a.y
		var rect := Rect2(Vector2(low) - Vector2(4,4), Vector2(high-low) + Vector2(9,15))
		if high.x <= low.x: rect = Rect2(150,70,50,50)
		cache[key] = rect
	head_bounds = cache[key]
	head_anchor = Vector2(head_bounds.get_center().x, head_bounds.end.y)
	var offset := Vector2.ZERO
	var atlas_size := Vector2(texture.get_size())
	if texture is AtlasTexture:
		offset = texture.region.position
		atlas_size = texture.atlas.get_size()
	material.set_shader_parameter("atlas_size", atlas_size)
	material.set_shader_parameter("head_rect", Vector4(head_bounds.position.x+offset.x,head_bounds.position.y+offset.y,head_bounds.size.x,head_bounds.size.y))
	material.set_shader_parameter("head_anchor", head_anchor+offset)
