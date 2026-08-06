extends Node2D
## 飘字: 在指定位置弹出文字,上飘 + 渐隐.

static func spawn(parent: Node, pos: Vector2, text: String, color: Color = Color.WHITE, distance: float = 40.0, duration: float = 0.8) -> void:
	if parent == null:
		return
	var ft: Node = (load("res://scripts/effects/floating_text.gd") as Script).new()
	ft._init_data(pos, text, color, distance, duration)
	parent.add_child(ft)

var _start_pos: Vector2
var _target_pos: Vector2
var _duration: float
var _elapsed: float = 0.0
var _label: Label
var _outline: int = 4

func _init_data(pos: Vector2, text: String, color: Color, distance: float, duration: float) -> void:
	position = pos
	_start_pos = pos
	_target_pos = pos + Vector2(0, -distance)
	_duration = duration
	_label = Label.new()
	_label.text = text
	_label.add_theme_color_override("font_color", color)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", _outline)
	_label.add_theme_font_size_override("font_size", 22 if distance < 50 else 32)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(-40, -16)
	_label.size = Vector2(80, 32)
	add_child(_label)
	scale = Vector2(0.5, 0.5)

func _process(delta: float) -> void:
	_elapsed += delta
	var t := _elapsed / _duration
	if t >= 1.0:
		queue_free()
		return
	position = _start_pos.lerp(_target_pos, t)
	var s := 1.0
	if t < 0.15:
		s = lerp(0.5, 1.2, t / 0.15)
	elif t < 0.3:
		s = lerp(1.2, 1.0, (t - 0.15) / 0.15)
	scale = Vector2(s, s)
	var a := 1.0
	if t > 0.6:
		a = 1.0 - (t - 0.6) / 0.4
	_label.modulate = Color(1, 1, 1, a)
