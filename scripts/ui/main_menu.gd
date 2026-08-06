extends Control
## 主菜单：开始 / 继续 / 剧情日志 / 设置 / 退出。氛围版（动态背景由 EmberBackground 提供）。
class_name MainMenu

## 已解锁关卡 id → 资源路径（与 levels/ 下 .tres 对应）。
const LEVEL_PATHS := {
	"level_01": "res://levels/level_01.tres",
	"level_02": "res://levels/level_02.tres",
	"level_03": "res://levels/level_03.tres",
	"level_04": "res://levels/level_04.tres",
	"level_05": "res://levels/level_05.tres",
}

@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/VBoxContainer/SubTitleLabel
@onready var button_container: VBoxContainer = $CenterContainer/VBoxContainer/ButtonContainer

var _settings_panel

func _ready() -> void:
	_settings_panel = preload("res://scripts/ui/settings_panel.gd").new()
	add_child(_settings_panel)
	_build_buttons()
	_play_intro()
	# BGM 钩子：主菜单背景乐（缺资产时 play_music 内部守卫使其为无害空操作）。
	AudioManager.play_music("bgm_menu", 1.5)

func _build_buttons() -> void:
	if not button_container:
		return
	for child in button_container.get_children():
		child.queue_free()

	var has_progress := GameManager.unlocked_levels.size() > 1 or GameManager.get_stars_for("level_01") > 0

	var start := _make_button("⚔️  新的征程")
	start.pressed.connect(_on_start_pressed)
	var cont := _make_button("📜  继续守卫")
	cont.disabled = not has_progress
	cont.pressed.connect(_on_continue_pressed)
	var story := _make_button("📖  剧情日志")
	story.pressed.connect(_on_story_pressed)
	var settings := _make_button("⚙️  设置")
	settings.pressed.connect(_on_settings_pressed)
	var quit := _make_button("🚪  退出游戏")
	quit.pressed.connect(_on_quit_pressed)

	button_container.add_child(start)
	button_container.add_child(cont)
	button_container.add_child(story)
	button_container.add_child(settings)
	button_container.add_child(quit)

func _make_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 54)
	b.modulate = Color(1.0, 1.0, 1.0, 0.0)  # 入场淡入
	return b

func _on_start_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	SceneRouter.go_to_level_select()

func _on_continue_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	var highest := ""
	for id in GameManager.unlocked_levels:
		if LEVEL_PATHS.has(id):
			highest = id
	if highest != "":
		SceneRouter.go_to_level(LEVEL_PATHS[highest])
	else:
		SceneRouter.go_to_level_select()

func _on_story_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	SceneRouter.go_to_story_log()

func _on_settings_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	_settings_panel.toggle()

func _on_quit_pressed() -> void:
	AudioManager.play_sfx("ui_click_2")
	get_tree().quit()

func _play_intro() -> void:
	# 减弱动效：直接置最终态，跳过所有补间动画
	if GameManager.reduce_motion:
		if title_label:
			title_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		if subtitle_label:
			subtitle_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		for b in button_container.get_children():
			if b is Button:
				b.modulate = Color(1.0, 1.0, 1.0, 1.0)
		return

	# 标题上浮淡入
	if title_label:
		title_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
		var t := create_tween()
		t.tween_property(title_label, "modulate:a", 1.0, 0.6).set_ease(Tween.EASE_OUT)
		# 标题呼吸缩放（循环）
		var breath := create_tween().set_loops()
		breath.tween_property(title_label, "scale", Vector2(1.04, 1.04), 1.6).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		breath.tween_property(title_label, "scale", Vector2(1.0, 1.0), 1.6).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	if subtitle_label:
		subtitle_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
		var t2 := create_tween()
		t2.tween_property(subtitle_label, "modulate:a", 1.0, 0.8).set_delay(0.2).set_ease(Tween.EASE_OUT)
	# 按钮错峰淡入
	var i := 0
	for b in button_container.get_children():
		if b is Button:
			var tw := create_tween()
			tw.tween_property(b, "modulate:a", 1.0, 0.4).set_delay(0.5 + i * 0.12).set_ease(Tween.EASE_OUT)
			i += 1
