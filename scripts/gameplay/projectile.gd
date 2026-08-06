extends Node2D
class_name Projectile

var target: Enemy = null
var speed: float = 500.0
var damage: float = 10.0
var splash_radius: float = 0.0
var slow_factor: float = 0.0
var slow_duration: float = 0.0
var color: Color = Color.ORANGE

var _target_pos: Vector2 = Vector2.ZERO

func setup(p_target: Enemy, p_speed: float, p_damage: float, p_splash: float, p_slow_factor: float, p_slow_duration: float, p_color: Color) -> void:
	target = p_target
	speed = p_speed
	damage = p_damage
	splash_radius = p_splash
	slow_factor = p_slow_factor
	slow_duration = p_slow_duration
	color = p_color
	if is_instance_valid(target):
		_target_pos = target.global_position

func _process(delta: float) -> void:
	if is_instance_valid(target):
		_target_pos = target.global_position
	
	var dir := (_target_pos - global_position)
	if dir.length() < 12.0:
		_hit()
		return
	
	global_position += dir.normalized() * speed * delta
	rotation = dir.angle()
	queue_redraw()

func _draw() -> void:
	# 动态绘制火光/脉冲子弹图形
	draw_circle(Vector2.ZERO, 6.0, color)
	draw_circle(Vector2.ZERO, 3.0, Color.WHITE)
	draw_line(Vector2(-8, 0), Vector2(0, 0), color * Color(1, 1, 1, 0.5), 3.0)

func _hit() -> void:
	AudioManager.play_sfx("projectile_hit", 0.0, 0.9 + randf() * 0.2)
	if is_instance_valid(target):
		if splash_radius > 0.0:
			var enemies = get_tree().get_nodes_in_group("enemies")
			for e in enemies:
				if is_instance_valid(e) and e is Enemy and e.global_position.distance_to(_target_pos) <= splash_radius:
					_apply_effect(e)
		else:
			_apply_effect(target)
	queue_free()

func _apply_effect(e: Enemy) -> void:
	e.take_damage(damage)
	if slow_factor > 0.0:
		e.apply_slow(1.0 - slow_factor, slow_duration)
