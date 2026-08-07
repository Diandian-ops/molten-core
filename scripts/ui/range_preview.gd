extends Node2D
## 建塔时的射程/溅射预览（ghost 环），挂在 BuildSlot 下，本地坐标 (0,0) = 槽位中心。
## 视觉风格刻意复用 Tower._draw 的射程环（青色主环 + 橙色溅射环），保证一致性。

var _range: float = 0.0
var _splash: float = 0.0

func setup(range_val: float, splash_val: float) -> void:
	_range = max(0.0, range_val)
	_splash = max(0.0, splash_val)
	queue_redraw()

func _draw() -> void:
	if _range <= 0.0:
		return
	draw_arc(Vector2.ZERO, _range, 0, TAU, 48, Color(0.0, 0.9, 1.0, 0.6), 2.0)
	draw_circle(Vector2.ZERO, _range, Color(0.0, 0.9, 1.0, 0.08))
	if _splash > 0.0:
		draw_arc(Vector2.ZERO, _splash, 0, TAU, 32, Color(1.0, 0.6, 0.2, 0.8), 2.0)
		draw_circle(Vector2.ZERO, _splash, Color(1.0, 0.4, 0.2, 0.10))
