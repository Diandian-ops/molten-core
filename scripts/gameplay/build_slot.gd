extends Node2D
## 建塔格：地图上的可布防位置，支持空槽建造、已建塔选中、射程指示与悬停反馈。
class_name BuildSlot

signal slot_selected(slot: BuildSlot)

@export var occupied: bool = false

@onready var indicator: Polygon2D = $Indicator
@onready var ground_sprite: Sprite2D = $Ground
@onready var area: Area2D = $Area2D

var current_tower: Tower = null

func _ready() -> void:
	set_occupied_visual(false)
	if area:
		area.mouse_entered.connect(_on_mouse_entered)
		area.mouse_exited.connect(_on_mouse_exited)

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		slot_selected.emit(self)

func _on_mouse_entered() -> void:
	if indicator and not occupied:
		indicator.color = Color(0.3, 1.0, 0.6, 0.6)
	if current_tower:
		current_tower.set_range_visible(true)

func _on_mouse_exited() -> void:
	if indicator and not occupied:
		indicator.color = Color(0.3, 0.9, 0.5, 0.25)
	if current_tower:
		current_tower.set_range_visible(false)

func build_tower(tower_data: TowerData) -> void:
	if occupied or tower_data == null or tower_data.scene == null:
		return
	if not GameManager.spend_currency(tower_data.cost):
		return
	var tower_instance: Tower = tower_data.scene.instantiate()
	add_child(tower_instance)
	tower_instance.setup(tower_data)
	current_tower = tower_instance
	occupied = true
	set_occupied_visual(true)
	AudioManager.play_sfx("tower_place")

func sell_tower() -> int:
	if not occupied or current_tower == null:
		return 0
	var sell_val := current_tower.get_sell_value()
	GameManager.add_currency(sell_val)
	AudioManager.play_sfx("ui_click_2")
	current_tower.queue_free()
	current_tower = null
	occupied = false
	set_occupied_visual(false)
	return sell_val

func set_occupied_visual(is_occupied: bool) -> void:
	if indicator:
		indicator.visible = not is_occupied
