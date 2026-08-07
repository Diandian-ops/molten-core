extends Control
## 关卡选择：数据驱动生成卡片（关名/星级/锁定态/Boss 提示），错峰淡入。
class_name LevelSelect

@export var level_entries: Array[Dictionary] = []

@onready var grid: GridContainer = $CenterContainer/Margin/VBoxContainer/GridContainer
@onready var back_button: Button = $BackButton

func _ready() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
	_populate()

func _populate() -> void:
	if not grid:
		return
	for child in grid.get_children():
		child.queue_free()

	var idx := 0
	for entry in level_entries:
		var level_id: String = entry.get("id", "")
		var level_path: String = entry.get("path", "")
		var display_name: String = entry.get("name", level_id)
		var unlocked := GameManager.is_level_unlocked(level_id)
		var stars := GameManager.get_stars_for(level_id)

		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(340, 120)
		# 统一卡片底色（普通态），hover/聚焦时切高亮态 —— 制造可点性反馈。
		card.add_theme_stylebox_override("panel", ThemeConstants.card_normal_style())

		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 8)

		var title := Label.new()
		title.text = ("🔒 " if not unlocked else "🗺️ ") + display_name
		title.add_theme_font_size_override("font_size", ThemeConstants.H2)

		var star := Label.new()
		if unlocked:
			star.text = "★★★".substr(0, stars) + "☆☆☆".substr(0, 3 - stars)
			star.add_theme_color_override("font_color", ThemeConstants.GOLD)
		else:
			star.text = "（未解锁）"
			star.add_theme_color_override("font_color", ThemeConstants.LOCKED_TEXT)
		star.add_theme_font_size_override("font_size", ThemeConstants.STAR)

		var hint := Label.new()
		hint.text = _boss_hint(level_id)
		hint.add_theme_color_override("font_color", ThemeConstants.TEXT_DIM_A)
		hint.add_theme_font_size_override("font_size", ThemeConstants.SMALL)

		vbox.add_child(title)
		vbox.add_child(star)
		vbox.add_child(hint)
		card.add_child(vbox)

		if unlocked:
			card.mouse_filter = Control.MOUSE_FILTER_STOP
			card.focus_mode = Control.FOCUS_ALL
			card.gui_input.connect(_on_card_clicked.bind(level_path))
			card.mouse_entered.connect(_on_card_hover.bind(card, true))
			card.mouse_exited.connect(_on_card_hover.bind(card, false))
			card.focus_entered.connect(_on_card_focus.bind(card, true))
			card.focus_exited.connect(_on_card_focus.bind(card, false))
			card.set_meta("hover", false)
			card.set_meta("focus", false)
		else:
			card.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.modulate = Color(ThemeConstants.LOCKED.r, ThemeConstants.LOCKED.g, ThemeConstants.LOCKED.b, 0.7)

		grid.add_child(card)

		# 入场淡入
		card.modulate.a = 0.0 if unlocked else 0.6
		var target_a := 1.0 if unlocked else 0.6
		var tw := create_tween()
		tw.tween_property(card, "modulate:a", target_a, 0.4).set_delay(0.15 + idx * 0.1).set_ease(Tween.EASE_OUT)
		idx += 1

## 卡片 hover / 聚焦：用 meta 记录双状态，任一为真即高亮，避免 mouse 与 focus 互相覆盖。
func _on_card_hover(card: PanelContainer, on: bool) -> void:
	card.set_meta("hover", on)
	_apply_card_state(card)

func _on_card_focus(card: PanelContainer, on: bool) -> void:
	card.set_meta("focus", on)
	_apply_card_state(card)

func _apply_card_state(card: PanelContainer) -> void:
	var hi: bool = card.get_meta("hover", false) or card.get_meta("focus", false)
	card.add_theme_stylebox_override("panel", ThemeConstants.card_hover_style() if hi else ThemeConstants.card_normal_style())

func _on_card_clicked(event: InputEvent, level_path: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		AudioManager.play_sfx("ui_click")
		SceneRouter.go_to_level(level_path)

func _on_back_button_pressed() -> void:
	AudioManager.play_sfx("ui_click_2")
	SceneRouter.go_to_main_menu()

func _boss_hint(level_id: String) -> String:
	match level_id:
		"level_01":
			return "Boss：熔岩巨像 · 慢速高血"
		"level_02":
			return "Boss：暗影行者 · 高速隐身"
		"level_03":
			return "Boss：深渊领者 · 半血狂暴"
		"level_04":
			return "Boss：暗影行者 · 高速狂暴"
		"level_05":
			return "Boss：熔心君主 · 双阶段狂暴召还"
		_:
			return ""
