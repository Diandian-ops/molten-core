extends Control
## 剧情日志：左列表（按进度解锁）+ 右详情。文案来自 resources/story/ 下的 StoryLog .tres。
class_name StoryLogMenu

@onready var list_container: VBoxContainer = $Margin/HBoxContainer/ListPanel/Margin/VBoxContainer
@onready var title_label: Label = $Margin/HBoxContainer/DetailPanel/Margin/VBoxContainer/TitleLabel
@onready var chapter_label: Label = $Margin/HBoxContainer/DetailPanel/Margin/VBoxContainer/ChapterLabel
@onready var body_label: Label = $Margin/HBoxContainer/DetailPanel/Margin/VBoxContainer/BodyLabel
@onready var back_button: Button = $BackButton

var _entries: Array[StoryLog] = []

func _ready() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	_load_entries()
	_populate()
	_select_first_unlocked()

func _load_entries() -> void:
	_entries.clear()
	var dir := DirAccess.open("res://resources/story/")
	if not dir:
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.ends_with(".tres"):
			var res := load("res://resources/story/" + fname) as StoryLog
			if res != null:
				_entries.append(res)
		fname = dir.get_next()
	dir.list_dir_end()
	_entries.sort_custom(func(a, b): return a.chapter < b.chapter)

func _populate() -> void:
	if not list_container:
		return
	for child in list_container.get_children():
		child.queue_free()
	for entry in _entries:
		var unlocked: bool = entry.unlock_level_id == "" or GameManager.is_level_unlocked(entry.unlock_level_id)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(240, 56)
		# 统一列表按钮视觉：普通态深底，hover/聚焦金色边框（与关卡卡一致的可点性反馈）。
		btn.add_theme_stylebox_override("normal", ThemeConstants.button_normal_style())
		btn.add_theme_stylebox_override("hover", ThemeConstants.button_hover_style())
		btn.add_theme_stylebox_override("focus", ThemeConstants.button_hover_style())
		btn.add_theme_stylebox_override("pressed", ThemeConstants.button_hover_style())
		btn.add_theme_stylebox_override("disabled", ThemeConstants.button_disabled_style())
		if unlocked:
			btn.text = "%s\n%s" % [entry.chapter, entry.title]
		else:
			btn.text = "🔒 %s" % entry.title
			btn.disabled = true
		btn.pressed.connect(_on_entry_pressed.bind(entry))
		list_container.add_child(btn)

func _select_first_unlocked() -> void:
	for entry in _entries:
		if entry.unlock_level_id == "" or GameManager.is_level_unlocked(entry.unlock_level_id):
			_show(entry)
			return

func _on_entry_pressed(entry: StoryLog) -> void:
	AudioManager.play_sfx("ui_click")
	_show(entry)

func _show(entry: StoryLog) -> void:
	if title_label:
		title_label.text = entry.title
	if chapter_label:
		chapter_label.text = entry.chapter
	if body_label:
		body_label.text = entry.body

func _on_back_pressed() -> void:
	AudioManager.play_sfx("ui_click_2")
	SceneRouter.go_to_main_menu()
