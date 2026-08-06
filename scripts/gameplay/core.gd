extends Area2D
## 熔核（核心）：受击与血量管理，支持主动技能。
## v0.3.0: 技能 / 受击闪烁 / 濒死心跳 / 摧毁粒子 / 护盾
class_name Core

const ParticleBurst = preload("res://scripts/effects/particle_burst.gd")
const FlashBurst = preload("res://scripts/effects/flash_burst.gd")
const FloatingText = preload("res://scripts/effects/floating_text.gd")

signal energy_depleted
signal core_damaged(amount: int, current: int)
signal core_healed(amount: int, current: int)

@onready var sprite: Sprite2D = $Sprite
@onready var flash_pulse_t: float = 0.0

var _shield_timer: float = 0.0
# 濒死脉冲使用定时器，避免每帧创建特效节点。
var _hurt_pulse_timer: float = 0.0
var max_energy: int = 10
var _hp: int = 10

# 技能 CD
var _heal_cd: float = 0.0
var _shock_cd: float = 0.0
var _shield_cd: float = 0.0
const HEAL_COOLDOWN := 30.0
const SHOCK_COOLDOWN := 25.0
const SHIELD_COOLDOWN := 40.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	add_to_group("core")
	_refresh_hud()

func _process(delta: float) -> void:
	if _shield_timer > 0.0:
		_shield_timer -= delta
		# 护盾视觉: sprite 发蓝光脉冲
		sprite.modulate = Color(0.6, 0.9, 1.0).lerp(Color.WHITE, 0.5 + 0.5 * sin(Time.get_ticks_msec() / 100.0))
	if _heal_cd > 0.0: _heal_cd -= delta
	if _shock_cd > 0.0: _shock_cd -= delta
	if _shield_cd > 0.0: _shield_cd -= delta

	if flash_pulse_t > 0.0:
		flash_pulse_t -= delta
		sprite.modulate = Color(2.5,0.3,0.3).lerp(Color.WHITE, 1.0 - flash_pulse_t / 0.2)

	# 濒死心跳 (仅视觉,由 HUD 处理声效)
	if _hp <= max_energy * 0.2:
		_draw_hurt_pulse()

func setup(max_hp: int) -> void:
	if max_hp > 0:
		max_energy = max_hp
	_hp = max_energy
	_refresh_hud()

func _refresh_hud() -> void:
	if GameManager:
		GameManager.set_core_energy(_hp, max_energy)

func take_damage(amount: int) -> void:
	if _shield_timer > 0.0:
		return  # 护盾免伤
	flash_pulse_t = 0.2
	_hp = max(0, _hp - amount)
	_refresh_hud()
	core_damaged.emit(amount, _hp)
	AudioManager.play_sfx("core_damaged")

	# 受击粒子 + 伤害飘字
	if get_tree().current_scene:
		ParticleBurst.spawn(get_tree().current_scene, global_position, Color(1.0, 0.2, 0.2), 10, 150.0, 0.5, 4.0)
		FloatingText.spawn(get_tree().current_scene, global_position + Vector2(0, -42), "-%d" % amount, Color(1.0, 0.35, 0.35), 52.0, 0.8)
		var cam := get_viewport().get_camera_2d()
		if cam and cam.has_method("add_trauma"):
			cam.add_trauma(0.35)

	if _hp <= 0:
		_destroy_core()

func heal(amount: int) -> void:
	_hp = min(max_energy, _hp + amount)
	core_healed.emit(amount, _hp)
	_refresh_hud()
	AudioManager.play_sfx("core_skill")
	if get_tree().current_scene:
		ParticleBurst.spawn(get_tree().current_scene, global_position, Color(0.2, 1.0, 0.4), 12, 100.0, 0.6, 4.0)

func _destroy_core() -> void:
	# 摧毁: 黑屏 + 粒子爆发 + 失败音
	AudioManager.play_sfx("core_destroyed")
	# 熔核崩毁叠加爆炸轰鸣，强化终局打击感。
	AudioManager.play_sfx("boom", -2.0)
	if get_tree().current_scene:
		ParticleBurst.spawn(get_tree().current_scene, global_position, Color(1.0, 0.4, 0.1), 60, 300.0, 1.2, 8.0)
		var cam := get_viewport().get_camera_2d()
		if cam and cam.has_method("add_trauma"):
			cam.add_trauma(1.0)
	energy_depleted.emit()

func _draw_hurt_pulse() -> void:
	if get_tree().current_scene:
		var t := (sin(Time.get_ticks_msec() / 200.0) + 1.0) * 0.5
		FlashBurst.spawn(get_tree().current_scene, global_position, Color(1.0, 0.2, 0.2, 0.3), 44.0, 0.1, true)

# === 熔核技能 ===
func get_hp() -> int: return _hp

func can_use_skill(skill_id: String) -> bool:
	match skill_id:
		"heal": return _heal_cd <= 0.0 and _hp < max_energy and GameManager and GameManager.currency >= skill_cost("heal")
		"shock": return _shock_cd <= 0.0 and GameManager and GameManager.currency >= skill_cost("shock")
		"shield": return _shield_cd <= 0.0 and _shield_timer <= 0.0 and GameManager and GameManager.currency >= skill_cost("shield")
	return false

func skill_cost(skill_id: String) -> int:
	match skill_id:
		"heal": return 30
		"shock": return 50
		"shield": return 80
	return 0

func use_skill(skill_id: String) -> bool:
	if not can_use_skill(skill_id):
		return false
	GameManager.spend_currency(skill_cost(skill_id))
	AudioManager.play_sfx("core_skill")
	match skill_id:
		"heal":
			_heal_cd = HEAL_COOLDOWN
			heal(2)
		"shock":
			_shock_cd = SHOCK_COOLDOWN
			_shock_wave()
		"shield":
			_shield_cd = SHIELD_COOLDOWN
			_shield_timer = 8.0
	return true

func _shock_wave() -> void:
	# 全场敌人伤 30 + 减速 30% 2s
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and e is Enemy:
			e.take_damage(30.0)
			e.apply_slow(0.7, 2.0)
	# 视觉: 全场扩张环
	if get_tree().current_scene:
		FlashBurst.spawn(get_tree().current_scene, global_position, Color(1.0, 0.7, 0.2), 500.0, 0.6, true)
		var cam := get_viewport().get_camera_2d()
		if cam and cam.has_method("add_trauma"):
			cam.add_trauma(0.4)

func get_skill_cd_remaining(skill_id: String) -> float:
	match skill_id:
		"heal": return _heal_cd
		"shock": return _shock_cd
		"shield": return _shield_cd
	return 0.0

func is_shield_active() -> bool:
	return _shield_timer > 0.0

# === 碰撞 ===
func _on_body_entered(body: Node) -> void:
	if body.has_method("get_damage_to_core"):
		take_damage(body.get_damage_to_core())
		body._absorbed_by_core = true
		if body.has_method("die_silently"):
			body.die_silently()
