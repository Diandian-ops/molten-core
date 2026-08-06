extends Node2D
## 通用粒子爆发: 在指定位置生成 N 个小方块,向随机方向飞,渐隐消失.

static func spawn(parent: Node, pos: Vector2, color: Color = Color.ORANGE, count: int = 8, speed: float = 120.0, lifetime: float = 0.5, size: float = 4.0) -> void:
	if parent == null:
		return
	var pb: Node = (load("res://scripts/effects/particle_burst.gd") as Script).new()
	pb._init_burst(pos, color, count, speed, lifetime, size)
	parent.add_child(pb)

var _color: Color
var _lifetime: float
var _elapsed: float = 0.0
var _offsets: Array[Vector2] = []
var _velocities: Array[Vector2] = []
var _sizes: Array[float] = []
var _rng := RandomNumberGenerator.new()

func _init_burst(pos: Vector2, color: Color, count: int, speed: float, lifetime: float, size: float) -> void:
	position = pos
	_color = color
	_lifetime = lifetime
	_rng.randomize()
	for i in count:
		var angle := _rng.randf() * TAU
		var v := Vector2(cos(angle), sin(angle)) * speed * _rng.randf_range(0.4, 1.0)
		_offsets.append(Vector2.ZERO)
		_velocities.append(v)
		_sizes.append(size * _rng.randf_range(0.6, 1.4))

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= _lifetime:
		queue_free()
		return
	for i in range(_velocities.size()):
		_offsets[i] += _velocities[i] * delta
		_velocities[i] = _velocities[i].lerp(Vector2.ZERO, delta * 4.0)
	queue_redraw()

func _draw() -> void:
	var t := _elapsed / _lifetime
	var alpha := 1.0 - t
	for i in range(_offsets.size()):
		var c := _color
		c.a = alpha
		var s := _sizes[i]
		draw_rect(Rect2(_offsets[i] - Vector2(s, s) * 0.5, Vector2(s, s)), c)
