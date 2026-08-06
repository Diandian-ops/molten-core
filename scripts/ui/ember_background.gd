extends Control
## 复用余烬背景：竖向渐变 + 浮动余烬点，纯代码、零资源依赖。
## 作为各菜单场景的首个子节点，全锚点铺满，保证视觉一致。

@export var intensity: float = 1.0          # 动画/亮度强度，建议 0.3 ~ 2.0
@export var ember_count: int = 36
@export var top_color: Color = Color(0.10, 0.06, 0.14, 1.0)
@export var bottom_color: Color = Color(0.02, 0.02, 0.04, 1.0)

var _embers: Array = []   # 每个元素: {pos:Vector2, vel:Vector2, size:float, phase:float, tw:float}
var _time: float = 0.0

func _ready() -> void:
	anchors_preset = Control.PRESET_FULL_RECT
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = -1
	_reset_embers()

func _reset_embers() -> void:
	_embers.clear()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var s := _view_size()
	for i in range(ember_count):
		_embers.append({
			"pos": Vector2(rng.randf() * s.x, rng.randf() * s.y),
			"vel": Vector2((rng.randf() - 0.5) * 8.0, -10.0 - rng.randf() * 22.0),
			"size": 1.5 + rng.randf() * 3.0,
			"phase": rng.randf() * TAU,
			"tw": rng.randf() * 2.0 + 1.0,
		})

func _view_size() -> Vector2:
	if size.x > 0.0:
		return size
	return Vector2(1280.0, 720.0)

func _process(delta: float) -> void:
	_time += delta
	var s := _view_size()
	for e in _embers:
		var pos: Vector2 = e.pos
		var vel: Vector2 = e.vel
		var ph: float = e.phase
		pos += vel * delta * intensity
		ph += delta * float(e.tw)
		pos.x += sin(ph) * 6.0 * delta
		if pos.y < -10.0:
			pos.y = s.y + 10.0
			pos.x = randf() * s.x
		if pos.x < -10.0:
			pos.x = s.x + 10.0
		elif pos.x > s.x + 10.0:
			pos.x = -10.0
		e.pos = pos
		e.phase = ph
	queue_redraw()

func _draw() -> void:
	var s := _view_size()
	# 竖向渐变（多条横带模拟）
	var bands := 32
	for i in range(bands):
		var t := float(i) / float(bands)
		var c := top_color.lerp(bottom_color, t)
		draw_rect(Rect2(0.0, t * s.y, s.x, s.y / float(bands) + 1.0), c)
	# 浮动余烬点
	for e in _embers:
		var ph: float = e.phase
		var a: float = (0.25 + 0.55 * (sin(ph) * 0.5 + 0.5)) * clamp(intensity, 0.3, 2.0)
		a = clamp(a, 0.0, 1.0)
		draw_circle(Vector2(e.pos.x, e.pos.y), float(e.size), Color(1.0, 0.5, 0.15, a))
