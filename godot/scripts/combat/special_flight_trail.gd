extends Node2D

var source: WeakRef
var points: Array[Vector2] = []
var remaining := 0.22
var tint := Color(0.35,0.8,1.0)

func setup(actor: Node, color: Color) -> void:
	source = weakref(actor)
	tint = color
	z_index = -1

func _process(delta: float) -> void:
	var actor: Node = source.get_ref() if source != null else null
	if not is_instance_valid(actor):
		queue_free()
		return
	if actor.hit_stop_timer > 0.0: return
	if actor.knockdown_state == &"KNOCKBACK":
		points.append(actor.global_position + Vector2(0,-75))
		if points.size() > 8: points.pop_front()
	else:
		remaining -= delta
		modulate.a = maxf(remaining/0.22,0.0)
		if remaining <= 0.0:
			queue_free()
			return
	queue_redraw()

func _draw() -> void:
	if points.size() < 2: return
	for i in range(1,points.size()):
		var weight := float(i)/points.size()
		var start := to_local(points[i-1])
		var end := to_local(points[i])
		draw_line(start,end,Color(tint,weight*0.18),24.0,true)
		for lane in [-1,0,1]:
			var offset := Vector2(0,lane*17.0)
			draw_line(start+offset,end+offset,Color(tint,weight*0.8),3.0,true)
		draw_line(start,end,Color(1,1,1,weight*0.8),2.0,true)
