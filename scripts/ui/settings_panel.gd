extends Control
## 设置面板：主菜单弹出的音量设置，拖动实时生效并持久化到 GameManager 存档。
class_name SettingsPanel

const BUSES := ["master", "sfx", "music"]
const BUS_LABELS := {"master": "主音量", "sfx": "音效", "music": "音乐"}

func _ready() -> void:
	_build_ui()
	hide()

func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(360, 280)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "⚙️ 设置"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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

	var close := Button.new()
	close.text = "关闭"
	close.pressed.connect(_on_close_pressed)
	vbox.add_child(close)

func _on_volume_changed(value: float, bus: String) -> void:
	GameManager.set_volume(bus, value)
	# 调音效时实时试听一下
	if bus == "sfx":
		AudioManager.play_sfx("ui_click")

func _on_close_pressed() -> void:
	AudioManager.play_sfx("ui_click_2")
	hide()

func toggle() -> void:
	if visible:
		hide()
	else:
		show()
