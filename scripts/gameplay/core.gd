extends Node2D
## 熔核本体：拥有强效发光光晕与受击沉浸反馈（在 UI 右上角展示熔核实时数值）。
class_name Core

signal energy_depleted

@onready var hit_area: Area2D = $HitArea
@onready var sprite: Sprite2D = $Sprite

var _time: float = 0.0
var _hurt_flash: float = 0.0

func _ready() -> void:
	if hit_area:
		hit_area.body_entered.connect(_on_body_entered)
		hit_area.area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	_time += delta * 3.0
	if _hurt_flash > 0.0:
		_hurt_flash -= delta
	
	if sprite:
		# 极柔和的动态悬浮感
		sprite.position.y = sin(_time * 1.5) * 3.0
	
	queue_redraw()

func _draw() -> void:
	var pulse := (sin(_time) + 1.0) * 0.5
	var r := 48.0 + pulse * 8.0
	var core_color := Color(1.0, 0.4, 0.1, 0.3 + pulse * 0.2)
	
	if _hurt_flash > 0.0:
		core_color = Color(1.0, 0.1, 0.1, 0.8)
		
	# 内层核心浓郁光晕
	draw_circle(Vector2.ZERO, r * 0.6, Color(1.0, 0.7, 0.2, 0.4 + pulse * 0.2))
	# 外层散射光环
	draw_circle(Vector2.ZERO, r, core_color)
	# 边缘能量脉冲线
	draw_arc(Vector2.ZERO, r + 6.0, 0, TAU, 48, Color(1.0, 0.7, 0.2, 0.6 + pulse * 0.4), 2.5)

func take_damage(amount: int) -> void:
	_hurt_flash = 0.4
	GameManager.damage_core(amount)
	AudioManager.play_sfx("core_damaged")
	if GameManager.is_core_destroyed():
		AudioManager.play_sfx("core_destroyed")
		energy_depleted.emit()

func _on_body_entered(body: Node) -> void:
	# 敌人接触熔核时由 core 统一结算（避免 enemy._reach_core 重复扣血）
	if body.has_method("get_damage_to_core") and not body.get("_absorbed_by_core"):
		take_damage(body.get_damage_to_core())
		body.set("_absorbed_by_core", true)
		if body.has_method("die_silently"):
			body.die_silently()

func _on_area_entered(area: Node) -> void:
	var body := area.get_parent()
	if body and body.has_method("get_damage_to_core"):
		take_damage(body.get_damage_to_core())
		if body.has_method("die_silently"):
			body.die_silently()
