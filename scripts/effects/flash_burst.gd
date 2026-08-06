extends Node2D
## 闪光: 圆形半径快速膨胀 + 渐隐. 命中反馈/熔核摧毁时用.

static func spawn(parent: Node, pos: Vector2, color: Color = Color.YELLOW, max_radius: float = 40.0, duration: float = 0.3, ring: bool = true) -> void:
	if parent == null:
		return
	var fb: Node = (load("res://scripts/effects/flash_burst.gd") as Script).new()
	fb._init_flash(pos, color, max_radius, duration, ring)
	parent.add_child(fb)

var _color: Color
var _max_r: float
var _duration: float
var _ring: bool
var _elapsed: float = 0.0

func _init_flash(pos: Vector2, color: Color, max_radius: float, duration: float, ring: bool) -> void:
	position = pos
	_color = color
	_max_r = max_radius
	_duration = duration
	_ring = ring

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= _duration:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var t := _elapsed / _duration
	var r := _max_r * t
	var alpha := 1.0 - t
	var c := _color
	c.a = alpha
	if _ring:
		draw_arc(Vector2.ZERO, r, 0, TAU, 24, c, 3.0)
	else:
		draw_circle(Vector2.ZERO, r, c)
