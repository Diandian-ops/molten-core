extends Node2D
class_name Tower
## 守卫塔逻辑：自动瞄准敌人、发射弹道特效，支持等级提升与出售功能。
## v0.3.0: 后坐力/火光/技能/分支升级树

const PROJECTILE_SCENE = preload("res://scenes/gameplay/projectile.tscn")
const ParticleBurst = preload("res://scripts/effects/particle_burst.gd")
const FlashBurst = preload("res://scripts/effects/flash_burst.gd")

@export var data: TowerData

@onready var range_area: Area2D = $RangeArea
@onready var range_shape: CollisionShape2D = $RangeArea/CollisionShape2D
@onready var sprite: Sprite2D = $Sprite

signal skill_used
signal upgraded(new_data: TowerData)
signal transformed_to(new_tower: Tower)

var level: int = 1
var total_invested_cost: int = 0
var _current_branch_choice: String = ""

var _skill_cooldown_timer: float = 0.0
var skill_ready: bool = true

var _recoil_t: float = 0.0
var _fire_flash_t: float = 0.0

var _targets_in_range: Array[Enemy] = []
var _attack_cooldown: float = 0.0
var _showing_range: bool = false
var _showing_skill_range: bool = false

func setup(tower_data: TowerData) -> void:
	data = tower_data
	level = 1
	total_invested_cost = data.cost
	_skill_cooldown_timer = 0.0
	skill_ready = true
	_update_range_shape()

func _ready() -> void:
	if range_area:
		range_area.body_entered.connect(_on_body_entered)
		range_area.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	_attack_cooldown -= delta
	if _skill_cooldown_timer > 0.0:
		_skill_cooldown_timer -= delta
		if _skill_cooldown_timer <= 0.0:
			skill_ready = true
	_cleanup_targets()

	if _recoil_t > 0.0:
		_recoil_t -= delta
		var t: float = clamp(1.0 - _recoil_t / 0.10, 0.0, 1.0)
		var offset := Vector2(-4.0 * (1.0 - t), 0).rotated(rotation)
		sprite.position = offset
	else:
		sprite.position = Vector2.ZERO

	if _fire_flash_t > 0.0:
		_fire_flash_t -= delta
		var a: float = clamp(_fire_flash_t / 0.10, 0.0, 1.0)
		sprite.modulate = Color(2.0, 1.6, 0.8).lerp(Color.WHITE, 1.0 - a)
	else:
		sprite.modulate = Color.WHITE

	if not _targets_in_range.is_empty():
		var target := _targets_in_range[0]
		if is_instance_valid(target):
			var dir := target.global_position - global_position
			rotation = lerp_angle(rotation, dir.angle(), delta * 12.0)
			if _attack_cooldown <= 0.0:
				_fire_at(target)
				_attack_cooldown = data.attack_interval

func _draw() -> void:
	if _showing_range and data:
		var current_r := get_current_range()
		draw_arc(Vector2.ZERO, current_r, 0, TAU, 48, Color(0.0, 0.9, 1.0, 0.6), 2.0)
		draw_circle(Vector2.ZERO, current_r, Color(0.0, 0.9, 1.0, 0.08))
	if _showing_skill_range and data:
		if data.skill_cone_angle > 0.0:
			draw_cone(Vector2.ZERO, Vector2.RIGHT.rotated(rotation), data.skill_radius, deg_to_rad(data.skill_cone_angle), Color(1.0, 0.4, 0.2, 0.2))
			draw_arc(Vector2.ZERO, data.skill_radius, rotation - deg_to_rad(data.skill_cone_angle/2), rotation + deg_to_rad(data.skill_cone_angle/2), 24, Color(1.0, 0.6, 0.2, 0.8), 2.0)
		elif data.skill_radius > 0.0:
			draw_circle(Vector2.ZERO, data.skill_radius, Color(1.0, 0.4, 0.2, 0.15))
			draw_arc(Vector2.ZERO, data.skill_radius, 0, TAU, 32, Color(1.0, 0.6, 0.2, 0.8), 2.0)

func set_range_visible(visible: bool) -> void:
	_showing_range = visible
	queue_redraw()

func set_skill_range_visible(visible: bool) -> void:
	_showing_skill_range = visible
	queue_redraw()

func get_current_damage() -> float:
	return data.damage + (level - 1) * data.damage_per_level

func get_current_range() -> float:
	return data.attack_range + (level - 1) * data.range_per_level

func get_upgrade_cost() -> int:
	return data.base_upgrade_cost * level

func can_upgrade() -> bool:
	return level < data.max_level

func is_branch_choice_pending() -> bool:
	return data.has_branch and level >= 2 and _current_branch_choice == ""

func upgrade() -> bool:
	if data.has_branch and level >= 2 and _current_branch_choice == "":
		return false
	if not can_upgrade():
		return false
	var cost := get_upgrade_cost()
	if not GameManager.spend_currency(cost):
		return false
	level += 1
	total_invested_cost += cost
	_update_range_shape()
	queue_redraw()
	AudioManager.play_sfx("tower_upgrade")
	_flash_upgrade()
	upgraded.emit(data)
	return true

func transform_to(new_data: TowerData) -> void:
	if new_data == null:
		return
	data = new_data
	level = 3
	_update_range_shape()
	queue_redraw()
	_flash_upgrade()
	transformed_to.emit(self)
	if get_tree().current_scene:
		ParticleBurst.spawn(get_tree().current_scene, global_position, Color.GOLD, 16, 150.0, 0.6, 6.0)
		FlashBurst.spawn(get_tree().current_scene, global_position, Color.GOLD, 50.0, 0.4, true)

func set_branch_choice(choice: String) -> void:
	_current_branch_choice = choice

func get_sell_value() -> int:
	return int(total_invested_cost * 0.7)

func _flash_upgrade() -> void:
	if sprite:
		sprite.modulate = Color(2.5, 2.0, 0.5)
		_fire_flash_t = 0.4
	if get_tree().current_scene:
		ParticleBurst.spawn(get_tree().current_scene, global_position, Color.GOLD, 10, 100.0, 0.4, 4.0)
		var cam := get_viewport().get_camera_2d()
		if cam and cam.has_method("add_trauma"):
			cam.add_trauma(0.2)

func _update_range_shape() -> void:
	if range_shape and range_shape.shape is CircleShape2D:
		(range_shape.shape as CircleShape2D).radius = get_current_range()

func _on_body_entered(body: Node) -> void:
	if body is Enemy:
		_targets_in_range.append(body)

func _on_body_exited(body: Node) -> void:
	if body is Enemy:
		_targets_in_range.erase(body)

func _cleanup_targets() -> void:
	_targets_in_range = _targets_in_range.filter(func(e): return is_instance_valid(e))

func _fire_at(enemy: Enemy) -> void:
	if not is_instance_valid(enemy):
		return
	_recoil_t = 0.10
	_fire_flash_t = 0.10

	var proj: Projectile = PROJECTILE_SCENE.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position

	var proj_color := Color.ORANGE
	if data.slow_factor > 0.0:
		proj_color = Color(0.0, 0.8, 1.0)
	elif data.splash_radius > 0.0:
		proj_color = Color(1.0, 0.3, 0.1)

	proj.setup(enemy, 550.0, get_current_damage(), data.splash_radius, data.slow_factor, data.slow_duration, proj_color)
	proj.is_homing = true

	# 枪口闪光：炮口位置亮闪 + 火花，强化开火手感
	if get_tree().current_scene:
		var muzzle := global_position + Vector2(34.0, 0.0).rotated(rotation)
		FlashBurst.spawn(get_tree().current_scene, muzzle, Color(1.0, 0.92, 0.55), 24.0, 0.12, true)
		ParticleBurst.spawn(get_tree().current_scene, muzzle, proj_color, 5, 130.0, 0.25, 3.0)

	AudioManager.play_sfx("tower_shoot", 0.0, 0.92 + randf() * 0.16)

func can_use_skill() -> bool:
	if data.skill_name == "":
		return false
	if not skill_ready:
		return false
	if GameManager.currency < data.skill_cost:
		return false
	return true

func use_skill() -> bool:
	if not can_use_skill():
		return false
	GameManager.spend_currency(data.skill_cost)
	skill_ready = false
	_skill_cooldown_timer = data.skill_cooldown

	if data.skill_radius > 0.0 or data.skill_cone_angle > 0.0:
		var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if not is_instance_valid(e) or not (e is Enemy):
				continue
			var ed: Enemy = e
			if data.skill_cone_angle > 0.0:
				var to_e: Vector2 = ed.global_position - global_position
				if to_e.length() > data.skill_radius:
					continue
				var ang: float = abs(angle_difference(to_e.angle(), rotation))
				if ang > deg_to_rad(data.skill_cone_angle / 2.0):
					continue
			else:
				if ed.global_position.distance_to(global_position) > data.skill_radius:
					continue
			if data.skill_damage > 0:
				ed.take_damage(float(data.skill_damage))
			if data.skill_slow > 0.0:
				ed.apply_slow(1.0 - data.skill_slow, data.skill_slow_duration)
			if data.skill_stun > 0.0:
				ed.apply_stun(data.skill_stun)

	AudioManager.play_sfx("tower_skill")
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(0.3)
	if get_tree().current_scene:
		if data.skill_cone_angle > 0.0:
			ParticleBurst.spawn(get_tree().current_scene, global_position + Vector2(data.skill_radius/2, 0).rotated(rotation), Color(1.0, 0.5, 0.1), 16, 200.0, 0.5, 5.0)
		else:
			FlashBurst.spawn(get_tree().current_scene, global_position, Color(1.0, 0.6, 0.2), data.skill_radius, 0.3, true)
			ParticleBurst.spawn(get_tree().current_scene, global_position, Color(1.0, 0.5, 0.1), 20, 180.0, 0.5, 5.0)

	skill_used.emit()
	return true

func get_skill_cooldown_remaining() -> float:
	return _skill_cooldown_timer

func get_skill_cooldown_ratio() -> float:
	if data.skill_cooldown <= 0.0:
		return 0.0
	return _skill_cooldown_timer / data.skill_cooldown

func draw_cone(center: Vector2, dir: Vector2, length: float, angle: float, color: Color) -> void:
	var arc_pts: Array[Vector2] = []
	for i in range(13):
		var a := -angle / 2.0 + angle * float(i) / 12.0
		arc_pts.append(dir.rotated(a) * length)
	for i in range(arc_pts.size() - 1):
		draw_colored_polygon(PackedVector2Array([Vector2.ZERO, arc_pts[i], arc_pts[i+1]]), color)
