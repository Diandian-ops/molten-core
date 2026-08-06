extends CharacterBody2D
## 敌人基础逻辑：沿多拐点路线/直线朝熔核巡航移动。
## v0.3.0: 受击飘字/眩晕/暴击/Boss多阶段/死亡粒子/倒地
class_name Enemy

const FloatingText = preload("res://scripts/effects/floating_text.gd")
const ParticleBurst = preload("res://scripts/effects/particle_burst.gd")
const FlashBurst = preload("res://scripts/effects/flash_burst.gd")

signal died(enemy: Enemy)

@export var data: EnemyData

@onready var sprite: Node2D = $Visual
@onready var health_bar: ProgressBar = $HealthBar
# 基础敌人旧场景没有这条血条；Boss 模板有则显示。
@onready var core_health_bar: ProgressBar = get_node_or_null("CoreHealthBar") as ProgressBar

var current_health: float = 0.0
var target_position: Vector2 = Vector2.ZERO
var _path_waypoints: PackedVector2Array = []
var _current_waypoint_index: int = 0

var _slow_timer: float = 0.0
var _slow_factor: float = 1.0
var _stun_timer: float = 0.0
var _dead: bool = false
var _flash_timer: float = 0.0

# Boss 多阶段
var _current_phase: int = 0
var _fired_phases: Dictionary = {}
var _phase_speed_mult: float = 1.0

# 命中反馈
var _hit_flash_t: float = 0.0
var _hit_critical: bool = false

# 避免撞核双扣血的守卫
var _absorbed_by_core: bool = false

func setup(enemy_data: EnemyData, target_pos: Vector2, waypoints: PackedVector2Array = []) -> void:
	data = enemy_data
	current_health = data.max_health
	target_position = target_pos
	_path_waypoints = waypoints
	_current_waypoint_index = 0

	if health_bar:
		health_bar.max_value = data.max_health
		health_bar.value = current_health

	if core_health_bar:
		core_health_bar.visible = is_boss()
		core_health_bar.max_value = data.max_health
		core_health_bar.value = current_health

	# 视觉
	if sprite:
		for c in sprite.get_children():
			if c is Sprite2D:
				if data.icon:
					c.texture = data.icon
				c.modulate = data.tint
	# 整体缩放 (boss 更大)
	scale = Vector2(data.scale, data.scale)
	if is_boss():
		AudioManager.play_sfx("boss_roar", 0.0, 1.0)
		var cam := get_viewport().get_camera_2d()
		if cam and cam.has_method("add_trauma"):
			cam.add_trauma(0.5)

func is_boss() -> bool:
	return data != null and data.is_boss

func _ready() -> void:
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if _dead:
		return
	# 眩晕
	if _stun_timer > 0.0:
		_stun_timer -= delta
		return

	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			_slow_factor = 1.0

	if _hit_flash_t > 0.0:
		_hit_flash_t -= delta
		if _hit_flash_t <= 0.0:
			sprite.modulate = Color.WHITE

	var next_target := target_position
	if not _path_waypoints.is_empty() and _current_waypoint_index < _path_waypoints.size():
		next_target = _path_waypoints[_current_waypoint_index]

	var dist_vec := (next_target - global_position)
	if dist_vec.length() < 8.0:
		if not _path_waypoints.is_empty() and _current_waypoint_index < _path_waypoints.size() - 1:
			_current_waypoint_index += 1
			next_target = _path_waypoints[_current_waypoint_index]
			dist_vec = (next_target - global_position)
		else:
			_reach_core()
			return

	var direction := dist_vec.normalized()
	velocity = direction * data.move_speed * _slow_factor * _phase_speed_mult
	move_and_slide()
	rotation = direction.angle()

	# Boss 阶段检测 (血线触发)
	_check_boss_phase()

func take_damage(amount: float, is_critical: bool = false) -> void:
	if _dead:
		return
	var mitigated: float = max(1.0, amount - data.armor)
	current_health -= mitigated
	if health_bar:
		health_bar.value = current_health
	if core_health_bar and is_boss():
		core_health_bar.value = current_health

	# 受击反馈
	sprite.modulate = Color(2.5, 0.4, 0.4)
	_hit_flash_t = 0.10
	_hit_punch()

	# 受击火花
	if get_tree().current_scene:
		ParticleBurst.spawn(get_tree().current_scene, global_position, Color(1.0, 0.6, 0.3), 4, 90.0, 0.3, 3.0)

	# 飘字 (伤害数字)
	if get_tree().current_scene and current_health > 0.0:
		if is_critical:
			AudioManager.play_sfx("critical_hit", 0.0, 0.9 + randf()*0.1)
			var cam := get_viewport().get_camera_2d()
			if cam and cam.has_method("add_trauma"):
				cam.add_trauma(0.2)
			FloatingText.spawn(get_tree().current_scene, global_position + Vector2(0,-20), str(int(mitigated)), Color(1.0,0.9,0.2), 55.0, 0.7)
		else:
			FloatingText.spawn(get_tree().current_scene, global_position + Vector2(0,-20), str(int(mitigated)), Color.WHITE, 45.0, 0.6)

	if current_health <= 0.0:
		_die_and_reward()

func apply_slow(factor: float, duration: float) -> void:
	_slow_factor = min(_slow_factor, factor)
	_slow_timer = max(_slow_timer, duration)

func apply_stun(duration: float) -> void:
	_stun_timer = max(_stun_timer, duration)
	# 眩晕视觉
	sprite.modulate = Color(0.7, 0.7, 1.0)

func get_damage_to_core() -> int:
	return data.damage_to_core

func die_silently() -> void:
	_dead = true
	died.emit(self)
	_spawn_death_effects()
	queue_free()

func _die_and_reward() -> void:
	if _dead:
		return
	_dead = true
	GameManager.add_currency(data.currency_reward)
	AudioManager.play_sfx("enemy_kill", 0.0, 0.85 + randf() * 0.3)
	# 飘钱
	if get_tree().current_scene:
		FloatingText.spawn(get_tree().current_scene, global_position + Vector2(0,-10), "+%d" % data.currency_reward, Color(1.0, 0.85, 0.2), 40.0, 0.8)
		# 死球粒子 + 爆闪环
		var col := Color(1.0, 0.3, 0.1) if not is_boss() else Color(1.0, 0.6, 0.0)
		ParticleBurst.spawn(get_tree().current_scene, global_position, col, 6 if not is_boss() else 20, 120.0, 0.5, 4.0)
		FlashBurst.spawn(get_tree().current_scene, global_position, col, 40.0 if not is_boss() else 90.0, 0.35, true)
	died.emit(self)
	queue_free()

func _spawn_death_effects() -> void:
	if get_tree().current_scene:
		ParticleBurst.spawn(get_tree().current_scene, global_position, Color(0.8, 0.2, 0.2), 8, 100.0, 0.4, 3.0)

## 受击挤压反馈：对视觉节点做一次快速 squash→还原，强化打击感。
func _hit_punch() -> void:
	if not is_instance_valid(sprite):
		return
	var tw := create_tween()
	tw.tween_property(sprite, "scale", Vector2(1.3, 0.75), 0.06).set_ease(Tween.EASE_OUT)
	tw.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.10).set_ease(Tween.EASE_OUT)

func _reach_core() -> void:
	if _absorbed_by_core:
		_dead = true
		died.emit(self)
		queue_free()
		return
	_absorbed_by_core = true
	var core := get_tree().get_first_node_in_group("core")
	if core and core.has_method("take_damage"):
		core.take_damage(data.damage_to_core)
	die_silently()

func _check_boss_phase() -> void:
	if not is_boss() or data.boss_phases.is_empty():
		return
	var ratio := current_health / data.max_health
	for p in data.boss_phases:
		if _fired_phases.has(p):
			continue
		if ratio <= p.hp_threshold:
			_fired_phases[p] = true
			_current_phase = p.hp_threshold
			# 狂暴加速：实例内倍率，作用于移动速度（不再写共享资源）
			if p.speed_mult > 1.0:
				_phase_speed_mult = max(_phase_speed_mult, p.speed_mult)
			if p.spawn_interval > 0.0:
				var sc := get_tree().current_scene
				if sc and sc.has_method("_on_boss_phase_passed"):
					sc._on_boss_phase_passed(p)
			# Boss 狂暴视觉
			sprite.modulate = Color(1.0, 0.5, 0.2)
			AudioManager.play_sfx("boss_roar", 0.0, 1.0)
			var cam := get_viewport().get_camera_2d()
			if cam and cam.has_method("add_trauma"):
				cam.add_trauma(0.5)
			# 不 break：允许同帧连续跨过多个阈值（如从满血直接掉到 25%）
