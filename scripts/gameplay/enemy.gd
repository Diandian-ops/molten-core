extends CharacterBody2D
## 敌人基础逻辑：沿多拐点路线/直线朝熔核巡航移动，受击闪红，死亡掉落晶币。
class_name Enemy

signal died(enemy: Enemy)

@export var data: EnemyData

@onready var sprite: Node2D = $Visual
@onready var health_bar: ProgressBar = $HealthBar

var current_health: float = 0.0
var target_position: Vector2 = Vector2.ZERO
var _path_waypoints: PackedVector2Array = []
var _current_waypoint_index: int = 0

var _slow_timer: float = 0.0
var _slow_factor: float = 1.0
var _dead: bool = false
var _flash_timer: float = 0.0

func setup(enemy_data: EnemyData, target_pos: Vector2, waypoints: PackedVector2Array = []) -> void:
	data = enemy_data
	current_health = data.max_health
	target_position = target_pos
	_path_waypoints = waypoints
	_current_waypoint_index = 0
	
	if health_bar:
		health_bar.max_value = data.max_health
		health_bar.value = current_health

func _ready() -> void:
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if _dead:
		return
	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			_slow_factor = 1.0

	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0 and sprite:
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
	velocity = direction * data.move_speed * _slow_factor
	move_and_slide()
	rotation = direction.angle()

func take_damage(amount: float) -> void:
	if _dead:
		return
	var mitigated: float = max(1.0, amount - data.armor)
	current_health -= mitigated
	if health_bar:
		health_bar.value = current_health
		
	if sprite:
		sprite.modulate = Color(2.5, 0.4, 0.4)
		_flash_timer = 0.12
		
	if current_health <= 0.0:
		_die_and_reward()

func apply_slow(factor: float, duration: float) -> void:
	_slow_factor = min(_slow_factor, factor)
	_slow_timer = max(_slow_timer, duration)

func get_damage_to_core() -> int:
	return data.damage_to_core

func die_silently() -> void:
	_dead = true
	died.emit(self)
	queue_free()

func _die_and_reward() -> void:
	if _dead:
		return
	_dead = true
	GameManager.add_currency(data.currency_reward)
	AudioManager.play_sfx("enemy_kill", 0.0, 0.85 + randf() * 0.3)
	died.emit(self)
	queue_free()

func _reach_core() -> void:
	# 如果已经被 core 的 body_entered 触发吸收，就不再重复扣血。
	if get("_absorbed_by_core"):
		_dead = true
		died.emit(self)
		queue_free()
		return
	set("_absorbed_by_core", true)
	var core := get_tree().get_first_node_in_group("core")
	if core and core.has_method("take_damage"):
		core.take_damage(data.damage_to_core)
	die_silently()