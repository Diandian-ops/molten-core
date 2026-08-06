extends Node2D
class_name Projectile
## 弹道单位：可直线或追踪目标，带拖尾效果。
## v0.3.0: homing/拖尾线/命中粒子/暴击

const FloatingText = preload("res://scripts/effects/floating_text.gd")
const ParticleBurst = preload("res://scripts/effects/particle_burst.gd")
const FlashBurst = preload("res://scripts/effects/flash_burst.gd")

var target: Node2D = null
var is_homing: bool = false
var speed: float = 500.0
var damage: float = 10.0
var splash_radius: float = 0.0
var slow_factor: float = 0.0
var slow_duration: float = 0.0
var color: Color = Color.ORANGE

var _velocity: Vector2 = Vector2.ZERO
var _trail: Array[Vector2] = []
var _max_trail: int = 6

func setup(enemy: Node2D, _speed: float, _damage: float, _splash: float, _slow: float, _slow_dur: float, _color: Color) -> void:
	target = enemy
	speed = _speed
	damage = _damage
	splash_radius = _splash
	slow_factor = _slow
	slow_duration = _slow_dur
	color = _color
	if is_instance_valid(target):
		_velocity = (target.global_position - global_position).normalized() * speed
		rotation = _velocity.angle()
	else:
		_velocity = Vector2(speed, 0)

func _process(delta: float) -> void:
	if is_homing and is_instance_valid(target):
		var dir := (target.global_position - global_position).normalized()
		_velocity = dir * speed
		rotation = dir.angle()
	elif not is_instance_valid(target):
		_hit()
		return

	_trail.push_front(global_position)
	if _trail.size() > _max_trail:
		_trail.resize(_max_trail)
	queue_redraw()

	global_position += _velocity * delta

	if is_instance_valid(target):
		if global_position.distance_to(target.global_position) < 10.0:
			_hit()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 4.0, color)
	draw_circle(Vector2.ZERO, 2.0, Color.WHITE)
	if _trail.size() > 1:
		for i in range(1, _trail.size()):
			var t := float(i) / _max_trail
			var c := color
			c.a = 0.4 * (1.0 - t)
			draw_line(_trail[i] - global_position, _trail[i-1] - global_position, c, 3.0 * (1.0 - t))

func _hit() -> void:
	AudioManager.play_sfx("projectile_hit", 0.0, 0.9 + randf() * 0.2)
	if get_tree().current_scene:
		ParticleBurst.spawn(get_tree().current_scene, global_position, color, 6, 130.0, 0.4, 3.0)
		FlashBurst.spawn(get_tree().current_scene, global_position, color, 18.0, 0.2, true)

	if is_instance_valid(target):
		if splash_radius > 0.0:
			var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
			for e in enemies:
				if is_instance_valid(e) and e is Enemy and e.global_position.distance_to(global_position) <= splash_radius:
					_apply_effect(e)
		else:
			_apply_effect(target)
	queue_free()

func _apply_effect(enemy: Node) -> void:
	if not is_instance_valid(enemy):
		return
	if enemy is Enemy:
		enemy.take_damage(damage)
		if slow_factor > 0.0 and slow_duration > 0.0:
			enemy.apply_slow(1.0 - slow_factor, slow_duration)
