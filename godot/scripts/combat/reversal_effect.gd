extends Node2D

var style := ""
var phase := "startup"
var elapsed := 0.0
var duration := 0.18
var source: WeakRef
var tint := Color(0.5, 0.85, 1.0)

func setup(actor: Node, event: String, seconds: float) -> void:
	source = weakref(actor)
	style = String(actor.fighter_definition.fighter_id)
	phase = event
	duration = maxf(seconds, 0.05)
	z_index = 20
	scale.x = actor.facing_direction
	if event != "impact": position = Vector2(0, -65)

func _process(delta: float) -> void:
	var actor: Node = source.get_ref() if source != null else null
	if not is_instance_valid(actor):
		queue_free()
		return
	if actor.hit_stop_timer > 0.0: return
	if phase in ["startup", "active"] and not actor.is_character_special_busy():
		queue_free()
		return
	elapsed += delta
	if elapsed >= duration:
		queue_free()
		return
	modulate.a = (1.0 - elapsed / duration) * 0.75
	queue_redraw()

func _draw() -> void:
	var r := 12.0 + elapsed / duration * 42.0
	if phase == "impact":
		if style in ["player_02_gou", "enemy_01_crusher"]:
			draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(1,0.7,0.3),4)
			draw_arc(Vector2.ZERO, r*0.6, 0, TAU, 32, tint,2)
			return
		if style in ["player_03_seiya", "enemy_02_shadow_boxer", "enemy_06_rio_flick_garcia"]:
			for i in range(3): draw_line(Vector2(-r,-12+i*12),Vector2(r,12-i*12),tint,3)
			return
		if style in ["enemy_08_leon_crow", "enemy_09_seiya"]:
			draw_arc(Vector2.ZERO,r,PI,TAU,24,Color(0.8,0.4,1),4)
			for i in range(3): draw_line(Vector2(-r+i*r,0),Vector2(-r+i*r,-r),tint,3)
			return
		for i in range(6):
			var v := Vector2.RIGHT.rotated(i * TAU / 6.0)
			draw_line(v * r * 0.3, v * r, tint, 3.0)
		return
	match style:
		"player_01_akky":
			draw_polyline(PackedVector2Array([Vector2(-25, 15), Vector2(0,-20), Vector2(10,5), Vector2(40,-15), Vector2(65,0)]), tint, 3)
		"player_02_gou":
			for i in range(3): draw_arc(Vector2(20, 60), r + i * 10, PI, TAU, 24, Color(1,0.7,0.3), 4)
		"player_03_seiya":
			for i in range(4): draw_line(Vector2(-60-i*8, -30+i*20), Vector2(40-i*8,-30+i*20), tint, 2)
		"enemy_01_crusher":
			draw_polyline(PackedVector2Array([Vector2(-65,60),Vector2(-30,45),Vector2(0,60),Vector2(30,40),Vector2(65,60)]), Color(1,0.6,0.3), 5)
		"enemy_02_shadow_boxer":
			for i in range(3): draw_arc(Vector2(-30-i*18,0), r*0.5, -PI/2, PI/2, 20, tint, 2)
		"enemy_03_masato_takahashi":
			draw_line(Vector2(5,0), Vector2(65,0), Color(1,0.85,0.5), 6)
			draw_arc(Vector2(45,0), r*0.5, -PI/2, PI/2, 18, tint, 2)
		"enemy_04_rei_kageyama":
			for i in range(2): draw_arc(Vector2(30,-i*24), r, -PI, PI/2, 24, tint, 3)
		"enemy_05_cross_murasame":
			draw_line(Vector2(-25,-30),Vector2(65,30),Color(0.8,0.4,1),4)
			draw_line(Vector2(-25,30),Vector2(65,-30),Color(0.8,0.4,1),4)
		"enemy_06_rio_flick_garcia":
			for i in range(3): draw_line(Vector2(10,-20+i*20),Vector2(65,-30+i*20),Color(1,0.4,0.3),3)
		"enemy_07_teki_fighter":
			for i in range(3): draw_arc(Vector2(20,i*10),r,-1.8,0.3,24,Color(0.8,0.4,1),3)
		"enemy_08_leon_crow":
			draw_arc(Vector2.ZERO,r,-PI*0.85,PI*0.85,32,Color(1,0.45,0.2),4)
			draw_line(Vector2(-r,-30),Vector2(0,-r),tint,3)
			draw_line(Vector2(0,-r),Vector2(r,-30),tint,3)
		"enemy_09_seiya":
			for i in range(3): draw_arc(Vector2(0,25-i*20),r*0.6,PI,TAU,24,Color(0.7,0.3,1),3)
