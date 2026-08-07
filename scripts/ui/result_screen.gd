extends Control
## 结算面板：显示胜利/失败、获得星级，提供重试/下一关/返回选择的按钮。氛围版（动态背景 + 入场动效）。
class_name ResultScreen

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/Margin/VBoxContainer/TitleLabel
@onready var stars_label: Label = $Panel/Margin/VBoxContainer/StarsLabel
@onready var hint_label: Label = $Panel/Margin/VBoxContainer/HintLabel
@onready var next_button: Button = $Panel/Margin/VBoxContainer/HBoxContainer/NextButton
@onready var retry_button: Button = $Panel/Margin/VBoxContainer/HBoxContainer/RetryButton
@onready var level_select_button: Button = $Panel/Margin/VBoxContainer/HBoxContainer/LevelSelectButton

var _level_id: String = ""
var _next_level_id: String = ""

func _ready() -> void:
	var result: Dictionary = SceneRouter.pending_result
	var victory: bool = result.get("victory", false)
	var stars: int = result.get("stars", 0)
	_level_id = result.get("level_id", "")
	_next_level_id = result.get("next_level_id", "")
	var reached_wave: int = result.get("reached_wave", 0)

	if title_label:
		title_label.text = "熔核守住了！" if victory else "熔核已熄灭……"
		title_label.add_theme_color_override("font_color", ThemeConstants.GOLD if victory else ThemeConstants.DANGER)
		title_label.add_theme_font_size_override("font_size", ThemeConstants.TITLE)
	if stars_label:
		stars_label.text = ("★".repeat(stars) + "☆".repeat(3 - stars)) if victory else ""
	if next_button:
		next_button.visible = victory and _next_level_id != ""
	if hint_label:
		if victory:
			hint_label.visible = true
			hint_label.text = "📖 通关解锁新剧情，主菜单「剧情日志」可查看"
		else:
			# 失败闭环：玩家需要知道「我撑到了第几波」，否则挫败感无锚点。
			hint_label.visible = reached_wave > 0
			hint_label.text = "坚持到第 %d 波 · 熔心仍在，再战！" % reached_wave

	# BGM: 1.5s 后根据胜负播放
	var timer := get_tree().create_timer(1.5)
	timer.timeout.connect(func ():
		if is_instance_valid(self):
			AudioManager.play_music("win" if victory else "lose", 0.5)
	)
	# 短 SFX 反馈 (核心摧毁/胜利短促音)
	if victory:
		AudioManager.play_sfx("core_damaged", -6.0)
	else:
		AudioManager.play_sfx("core_destroyed")

	# 所有按钮 click 音
	for btn in [next_button, retry_button, level_select_button]:
		if btn and not btn.pressed.is_connected(_play_click):
			btn.pressed.connect(_play_click.bind(victory))

	_play_intro()

func _play_intro() -> void:
	if not panel:
		return
	panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	panel.scale = Vector2(0.85, 0.85)
	var t := create_tween()
	t.tween_property(panel, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(panel, "scale", Vector2(1.0, 1.0), 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	if stars_label and stars_label.text != "":
		stars_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
		stars_label.scale = Vector2(0.2, 0.2)
		var t2 := create_tween()
		t2.tween_property(stars_label, "modulate:a", 1.0, 0.4).set_delay(0.35)
		t2.parallel().tween_property(stars_label, "scale", Vector2(1.0, 1.0), 0.5).set_delay(0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _play_click(victory: bool) -> void:
	AudioManager.play_sfx("ui_click" if victory else "ui_click_2")

func _on_retry_button_pressed() -> void:
	if _level_id != "":
		SceneRouter.go_to_level("res://levels/%s.tres" % _level_id)
	else:
		SceneRouter.go_to_level_select()

func _on_next_button_pressed() -> void:
	if _next_level_id != "":
		SceneRouter.go_to_level("res://levels/%s.tres" % _next_level_id)

func _on_level_select_button_pressed() -> void:
	SceneRouter.go_to_level_select()
