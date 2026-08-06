extends Node2D
## 守卫塔逻辑：自动瞄准敌人、发射弹道特效，支持等级提升与出售功能。
class_name Tower

const PROJECTILE_SCENE = preload("res://scenes/gameplay/projectile.tscn")

@export var data: TowerData

@onready var range_area: Area2D = $RangeArea
@onready var range_shape: CollisionShape2D = $RangeArea/CollisionShape2D
@onready var sprite: Sprite2D = $Sprite

var level: int = 1
var total_invested_cost: int = 0

var _targets_in_range: Array[Enemy] = []
var _attack_cooldown: float = 0.0
var _showing_range: bool = false

func setup(tower_data: TowerData) -> void:
	data = tower_data
	level = 1
	total_invested_cost = data.cost
	_update_range_shape()

func _ready() -> void:
	if range_area:
		range_area.body_entered.connect(_on_body_entered)
		range_area.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	_attack_cooldown -= delta
	_cleanup_targets()
	
	if not _targets_in_range.is_empty():
		var target := _targets_in_range[0]
		if is_instance_valid(target):
			# 炮塔平滑转向敌人
			var dir := target.global_position - global_position
			rotation = lerp_angle(rotation, dir.angle(), delta * 12.0)
			
			if _attack_cooldown <= 0.0:
				_fire_at(target)
				_attack_cooldown = data.attack_interval
				AudioManager.play_sfx("tower_shoot", 0.0, 0.92 + randf() * 0.16)

func _draw() -> void:
	if _showing_range and data:
		var current_r := get_current_range()
		draw_arc(Vector2.ZERO, current_r, 0, TAU, 48, Color(0.0, 0.9, 1.0, 0.6), 2.0)
		draw_circle(Vector2.ZERO, current_r, Color(0.0, 0.9, 1.0, 0.08))

func set_range_visible(visible: bool) -> void:
	_showing_range = visible
	queue_redraw()

func get_current_damage() -> float:
	return data.damage + (level - 1) * data.damage_per_level

func get_current_range() -> float:
	return data.attack_range + (level - 1) * data.range_per_level

func get_upgrade_cost() -> int:
	return data.base_upgrade_cost * level

func can_upgrade() -> bool:
	return level < data.max_level

func upgrade() -> bool:
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
	return true

func get_sell_value() -> int:
	return int(total_invested_cost * 0.7)

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
	
	var proj: Projectile = PROJECTILE_SCENE.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
	
	var proj_color := Color.ORANGE
	if data.slow_factor > 0.0:
		proj_color = Color(0.0, 0.8, 1.0)
	elif data.splash_radius > 0.0:
		proj_color = Color(1.0, 0.3, 0.1)
		
	proj.setup(enemy, 550.0, get_current_damage(), data.splash_radius, data.slow_factor, data.slow_duration, proj_color)
