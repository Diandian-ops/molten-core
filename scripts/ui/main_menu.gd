extends Control
## 主菜单：开始游戏、继续游戏、退出。
class_name MainMenu

@onready var continue_button: Button = $CenterContainer/VBoxContainer/ContinueButton

func _ready() -> void:
	if continue_button:
		continue_button.disabled = GameManager.unlocked_levels.size() <= 1 and GameManager.get_stars_for("level_01") <= 0

func _on_start_button_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	SceneRouter.go_to_level_select()

func _on_continue_button_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	SceneRouter.go_to_level_select()

func _on_quit_button_pressed() -> void:
	AudioManager.play_sfx("ui_click_2")
	get_tree().quit()
