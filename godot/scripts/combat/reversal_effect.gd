extends Node2D

const AURA_TEXTURE = preload("res://assets/effects/special_v1/aura.png")
const IMPACT_TEXTURE = preload("res://assets/effects/special_v1/impact.png")

var style := ""
var phase := "startup"
var elapsed := 0.0
var duration := 0.18
var source: WeakRef
var tint := Color(0.5, 0.85, 1.0)
var contact_point := Vector2(40,-20)

func setup(actor: Node, event: String, seconds: float) -> void:
	source = weakref(actor)
	style = String(actor.fighter_definition.fighter_id)
	tint = _style_color()
	phase = event
	duration = maxf(seconds, 0.05)
	z_index = 20
	scale.x = actor.facing_direction
	if event != "impact": position = Vector2(0, -65)
	if event == "active" and actor.special_area != null:
		contact_point = Vector2(actor.special_area.position.x * actor.facing_direction,actor.special_area.position.y) - position
	queue_redraw()

func _style_color() -> Color:
	return color_for_style(style)

static func color_for_style(fighter_style: String) -> Color:
	match fighter_style:
		"player_02_gou", "enemy_01_crusher", "enemy_03_masato_takahashi": return Color(1.0, 0.65, 0.18)
		"enemy_05_cross_murasame", "enemy_07_teki_fighter", "enemy_09_seiya": return Color(0.8, 0.35, 1.0)
		"enemy_06_rio_flick_garcia", "enemy_08_leon_crow": return Color(1.0, 0.35, 0.18)
		_: return Color(0.25, 0.85, 1.0)

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
	modulate.a = pow(1.0 - elapsed / duration, 0.65)
	queue_redraw()

func _draw() -> void:
	var r := 12.0 + elapsed / duration * 42.0
	if phase == "wall":
		_draw_special_impact()
		draw_line(Vector2(0,-90),Vector2(0,90),Color(tint,0.4),14.0)
		draw_line(Vector2(0,-75),Vector2(0,75),Color.WHITE,3.0)
		return
	if phase == "impact":
		if style == "enemy_07_teki_fighter":
			# A palm impact opens into five short finger trails, away from the face.
			for i in range(5):
				var spread := Vector2(1.0,(i-2)*0.3).normalized()
				draw_line(spread*8.0,spread*(22.0+r*0.35),Color(tint,0.7),2.0,true)
			draw_arc(Vector2.ZERO,14.0+r*0.2,-PI*0.5,PI*0.5,20,Color.WHITE,2.0,true)
			return
		_draw_special_impact()
	else:
		_draw_body_aura()
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
			var sweep := -elapsed/duration*TAU
			draw_arc(Vector2(0,-55),105.0,sweep,sweep+PI*1.25,48,Color(tint,0.22),18.0,true)
			draw_arc(Vector2(0,-55),105.0,sweep,sweep+PI*1.25,48,Color.WHITE,3.0,true)
		"enemy_01_crusher":
			draw_polyline(PackedVector2Array([Vector2(-65,60),Vector2(-30,45),Vector2(0,60),Vector2(30,40),Vector2(65,60)]), Color(1,0.6,0.3), 5)
			if phase == "active":
				# Follow the two fists from the overhead windup down toward the target.
				var progress := elapsed/duration
				var end_angle := lerpf(-PI*0.70,PI*0.15,progress)
				draw_arc(Vector2(0,-25),100.0,-PI*0.70,end_angle,32,Color(tint,0.28),14.0,true)
				draw_arc(Vector2(0,-25),100.0,-PI*0.70,end_angle,32,Color.WHITE,3.0,true)
		"enemy_02_shadow_boxer":
			for i in range(3): draw_arc(Vector2(-30-i*18,0), r*0.5, -PI/2, PI/2, 20, tint, 2)
		"enemy_03_masato_takahashi":
			draw_line(Vector2(5,0), Vector2(65,0), Color(1,0.85,0.5), 6)
			draw_arc(Vector2(45,0), r*0.5, -PI/2, PI/2, 18, tint, 2)
		"enemy_04_rei_kageyama":
			if phase == "active":
				# Rising arc follows the uppercut box, never a horizontal punch flash.
				var progress := elapsed/duration
				var center := contact_point+Vector2(-35,20)
				draw_arc(center,48.0,PI*0.6,PI*0.6+progress*PI*1.25,32,Color(tint,0.3),10.0,true)
				draw_arc(center,48.0,PI*0.6,PI*0.6+progress*PI*1.25,32,Color.WHITE,2.0,true)
		"enemy_05_cross_murasame":
			draw_line(contact_point+Vector2(-35,-25),contact_point+Vector2(35,25),Color(0.8,0.4,1),3)
			draw_line(contact_point+Vector2(-35,25),contact_point+Vector2(35,-25),Color(0.8,0.4,1),3)
		"enemy_06_rio_flick_garcia":
			for i in range(3): draw_line(Vector2(10,-20+i*20),Vector2(65,-30+i*20),Color(1,0.4,0.3),3)
		"enemy_07_teki_fighter":
			if phase == "active":
				var progress := elapsed/duration
				for i in range(3):
					var edge := contact_point+Vector2(0,(i-1)*12)
					draw_line(edge-Vector2(35.0+progress*20.0,0),edge+Vector2(progress*18.0,-4),Color(tint,0.55),2.0,true)
		"enemy_08_leon_crow":
			draw_arc(Vector2.ZERO,r,-PI*0.85,PI*0.85,32,Color(1,0.45,0.2),4)
			draw_line(Vector2(-r,-30),Vector2(0,-r),tint,3)
			draw_line(Vector2(0,-r),Vector2(r,-30),tint,3)
		"enemy_09_seiya":
			for i in range(3): draw_arc(Vector2(0,25-i*20),r*0.6,PI,TAU,24,Color(0.7,0.3,1),3)

func _draw_body_aura() -> void:
	if style == "enemy_04_rei_kageyama":
		# Thin ground spiral and side lift lines preserve mohawk, face and vest.
		var progress := elapsed/duration
		for i in range(2):
			var ring := PackedVector2Array()
			for step in range(33):
				var angle := step*TAU/32.0+progress*PI+i*PI
				ring.append(Vector2(cos(angle)*(40+i*9),sin(angle)*8+62-i*5))
			draw_polyline(ring,Color(tint,0.35),2.0,true)
		if phase == "startup":
			for side in [-1.0,1.0]:
				draw_line(Vector2(side*68,35),Vector2(side*60,-45-progress*40),Color(tint,0.3),2.0,true)
		return
	if style == "enemy_05_cross_murasame":
		# Technique: narrow directional edges frame the grip, with no body fill.
		for side in [-1.0, 1.0]:
			draw_line(Vector2(55*side,-120),Vector2(85*side,-55),Color(tint,0.45),2.0,true)
			draw_line(Vector2(85*side,-55),Vector2(55*side,10),Color(tint,0.35),2.0,true)
		draw_arc(Vector2(0,62),48.0,0,TAU,32,Color(tint,0.4),2.0,true)
		return
	if style == "enemy_05_cross_murasame":
		# Sparse grip arcs preserve the jacket, fringe, chain and both hands.
		if phase == "startup":draw_arc(Vector2(30,-8),23.0,PI*0.5,PI*1.6,20,Color(tint,0.45),2.0,true)
		if phase == "finish":draw_arc(Vector2(0,62),38.0,0,TAU,24,Color(tint,0.25),2.0,true)
		return
	if style == "enemy_07_teki_fighter":
		# Startup charge sits beside the coiled hand; no full-body aura.
		if phase == "startup":
			for i in range(2):draw_arc(Vector2(25,-10),14.0+i*7.0,PI*0.5,PI*1.8,20,Color(tint,0.4),2.0,true)
		if phase == "finish":draw_arc(Vector2(0,62),32.0,0,TAU,24,Color(tint,0.25),2.0,true)
		return
	if style in ["enemy_02_shadow_boxer","player_03_seiya","enemy_09_seiya"]:
		# Keep the cap, gloves and counterpunch silhouette readable.
		draw_arc(Vector2(0,-45),95.0,0,TAU,48,Color(tint,0.25),2.0,true)
		draw_arc(Vector2(0,62),42.0,0,TAU,32,Color(tint,0.40),2.0,true)
		return
	var progress := elapsed / duration
	var pulse := 1.0 + 0.04 * sin(progress * TAU * 2.0)
	draw_texture_rect(AURA_TEXTURE,Rect2(Vector2(-95,-170)*pulse,Vector2(190,245)*pulse),false,Color(tint,0.30 if style == "player_03_seiya" else 0.8))
	var strength := 1.15 if phase == "active" else 1.0
	if phase == "finish": strength = 0.85
	var contour := PackedVector2Array()
	for i in range(49):
		var angle := float(i) * TAU / 48.0
		var ripple := 1.0 + 0.07 * sin(angle * 9.0 + progress * TAU)
		contour.append(Vector2(cos(angle) * 60.0, sin(angle) * 105.0) * ripple * strength + Vector2(0,-38))
	# Transparent interior keeps the character pose legible; the bright rim signals the special.
	draw_colored_polygon(contour, Color(tint, 0.10))
	draw_polyline(contour, Color(tint, 0.20), 15.0, true)
	draw_polyline(contour, Color(tint, 0.18), 2.0, true)
	for i in range(9):
		var x := -64.0 + i * 16.0
		var y := 50.0 - fmod(progress * 125.0 + i * 23.0, 150.0)
		draw_line(Vector2(x,y), Vector2(x * 0.83,y-22), Color(tint,0.85), 3.0, true)
	var ring := PackedVector2Array()
	for i in range(49):
		var angle := float(i) * TAU / 48.0
		ring.append(Vector2(cos(angle) * (68.0 + progress * 15.0), sin(angle) * 13.0 + 62.0))
	draw_polyline(ring, Color(tint,0.8), 3.0, true)
	if phase == "active":
		if style == "player_03_seiya":
			var sweep := -progress*TAU
			draw_arc(Vector2(0,-55),105.0,sweep,sweep+PI*1.1,48,Color(tint,0.3),12.0,true)
			draw_arc(Vector2(0,-55),105.0,sweep,sweep+PI*1.1,48,Color.WHITE,3.0,true)
			return
		draw_circle(Vector2(65,-20), 25.0, Color(tint,0.22))
		draw_circle(Vector2(65,-20), 10.0, Color(1,1,1,0.9))
		for i in range(5):
			var y := -60.0 + i * 20.0
			draw_line(Vector2(-52,y),Vector2(95,y-12),Color(tint,0.5),3.0,true)
		draw_arc(Vector2(38,-20), 62.0, -1.3, 1.3, 32, Color(tint,0.25), 18.0, true)
		draw_arc(Vector2(38,-20), 62.0, -1.3, 1.3, 32, Color(1,1,1,0.9), 4.0, true)

func _draw_special_impact() -> void:
	if style == "enemy_04_rei_kageyama":
		var radius := 18.0+elapsed/duration*25.0
		draw_arc(Vector2.ZERO,radius,0,TAU,32,Color(tint,0.6),2.0,true)
		for i in range(3):
			draw_line(Vector2(-16+i*16,12),Vector2(-10+i*10,-radius),Color(1,1,1,0.7),2.0,true)
		return
	if style in ["player_03_seiya","enemy_09_seiya"]:
		draw_arc(Vector2.ZERO,28.0,0,TAU,32,Color(tint,0.5),3.0,true)
		draw_arc(Vector2.ZERO,16.0,0,TAU,24,Color(1,1,1,0.4),2.0,true)
		return
	if style == "enemy_02_shadow_boxer":
		var counter_radius := 22.0+elapsed/duration*25.0
		draw_arc(Vector2.ZERO,counter_radius,0,TAU,32,Color(tint,0.65),2.0,true)
		return
	var progress := elapsed / duration
	var radius := 42.0 + progress * 65.0
	draw_texture_rect(IMPACT_TEXTURE,Rect2(Vector2.ONE*-radius*1.35,Vector2.ONE*radius*2.7),false,Color(tint,0.9))
	draw_circle(Vector2.ZERO, radius * 0.65, Color(tint,0.16))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 48, Color(tint,0.3), 14.0, true)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 48, tint, 4.0, true)
	draw_arc(Vector2.ZERO, radius * 0.65, 0, TAU, 40, Color(1,1,1,0.9), 3.0, true)
	for i in range(10):
		var direction := Vector2.RIGHT.rotated(i * TAU / 10.0 + 0.15)
		draw_line(direction * radius * 0.28, direction * radius * 1.25, Color(tint,0.35), 10.0, true)
		draw_line(direction * radius * 0.28, direction * radius * 1.25, Color(1,1,1,0.95), 3.0, true)
