extends Control
## 设置面板：主菜单弹出的音量设置，拖动实时生效并持久化到 GameManager 存档。
## 显示为模态（半透明背景拦截背后主菜单的点击），并提供「重置为默认」。
class_name SettingsPanel

const BUSES := ["master", "sfx", "music"]
const BUS_LABELS := {"master": "主音量", "sfx": "音效", "music": "音乐"}
const DEFAULT_VOLUME := 1.0

var _sliders: Dictionary = {}
var _applying := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	hide()

func _build_ui() -> void:
	# 半透明背景，拦截背后主菜单的点击，实现模态效果
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.55)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(360, 420)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "⚙️ 设置"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", ThemeConstants.TITLE)
	vbox.add_child(title)

	for bus in BUSES:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = BUS_LABELS[bus]
		label.custom_minimum_size = Vector2(64, 0)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.01
		slider.value = GameManager.get_volume(bus)
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.value_changed.connect(_on_volume_changed.bind(bus))
		row.add_child(label)
		row.add_child(slider)
		vbox.add_child(row)
		_sliders[bus] = slider

	# 减弱动效 + 全屏开关
	var motion_box := HBoxContainer.new()
	var motion_label := Label.new()
	motion_label.text = "减弱动效"
	motion_label.custom_minimum_size = Vector2(64, 0)
	var motion_cb := CheckBox.new()
	motion_cb.button_pressed = GameManager.reduce_motion
	motion_cb.toggled.connect(_on_reduce_motion_toggled)
	motion_box.add_child(motion_label)
	motion_box.add_child(motion_cb)
	vbox.add_child(motion_box)

	var fs_box := HBoxContainer.new()
	var fs_label := Label.new()
	fs_label.text = "全屏"
	fs_label.custom_minimum_size = Vector2(64, 0)
	var fs_cb := CheckBox.new()
	fs_cb.button_pressed = GameManager.fullscreen
	fs_cb.toggled.connect(_on_fullscreen_toggled)
	fs_box.add_child(fs_label)
	fs_box.add_child(fs_cb)
	vbox.add_child(fs_box)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var reset := Button.new()
	reset.text = "重置为默认"
	reset.custom_minimum_size = Vector2(140, 48)
	reset.pressed.connect(_on_reset_pressed)
	var close := Button.new()
	close.text = "关闭"
	close.custom_minimum_size = Vector2(140, 48)
	close.pressed.connect(_on_close_pressed)
	btn_row.add_child(reset)
	btn_row.add_child(close)
	vbox.add_child(btn_row)

func _on_volume_changed(value: float, bus: String) -> void:
	GameManager.set_volume(bus, value)
	if not _applying and bus == "sfx":
		AudioManager.play_sfx("ui_click")

func _on_reduce_motion_toggled(value: bool) -> void:
	GameManager.set_reduce_motion(value)
	AudioManager.play_sfx("ui_click")

func _on_fullscreen_toggled(value: bool) -> void:
	GameManager.set_fullscreen(value)
	AudioManager.play_sfx("ui_click")

func _on_reset_pressed() -> void:
	_applying = true
	for bus in BUSES:
		GameManager.set_volume(bus, DEFAULT_VOLUME)
		_sliders[bus].value = DEFAULT_VOLUME
	_applying = false
	AudioManager.play_sfx("ui_click_2")

func _on_close_pressed() -> void:
	AudioManager.play_sfx("ui_click_2")
	hide()

func toggle() -> void:
	if visible:
		hide()
	else:
		show()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
