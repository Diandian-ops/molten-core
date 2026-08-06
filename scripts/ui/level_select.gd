extends Control
## 关卡选择：列出所有关卡按钮，依据 GameManager 解锁状态启用/禁用，显示已获得星级。
class_name LevelSelect

@export var level_entries: Array[Dictionary] = []

@onready var list_container: VBoxContainer = $ScrollContainer/VBoxContainer

func _ready() -> void:
	_populate_levels()

func _populate_levels() -> void:
	if not list_container:
		return
	for child in list_container.get_children():
		child.queue_free()

	for entry in level_entries:
		var level_id: String = entry.get("id", "")
		var level_path: String = entry.get("path", "")
		var display_name: String = entry.get("name", level_id)

		var button := Button.new()
		var unlocked := GameManager.is_level_unlocked(level_id)
		var stars := GameManager.get_stars_for(level_id)

		var star_str := "  " + "★".repeat(stars) + "☆".repeat(3 - stars)
		button.text = "🎯 %s %s" % [display_name, star_str if unlocked else " (未解锁)"]
		button.disabled = not unlocked
		button.custom_minimum_size = Vector2(360, 52)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func ():
			AudioManager.play_sfx("ui_click")
			SceneRouter.go_to_level(level_path)
		)
		list_container.add_child(button)

func _on_level_button_pressed(level_path: String) -> void:
	SceneRouter.go_to_level(level_path)

func _on_back_button_pressed() -> void:
	AudioManager.play_sfx("ui_click_2")
	SceneRouter.go_to_main_menu()
