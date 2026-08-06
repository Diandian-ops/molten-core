extends Camera2D
## 屏幕震动: 任何代码调 `Camera2D.add_trauma(0.3)` 即可震.
## trauma 衰减率 0.05/帧, 1.0 = 满震.
## 偏移公式: shake_offset = trauma^2 * max_offset * random

class_name ShakeCamera2D

@export var max_offset: Vector2 = Vector2(12, 8)
@export var max_rotation: float = 0.04
@export var decay: float = 1.5  # trauma 衰减/秒
@export var noise_speed: float = 30.0

var trauma: float = 0.0
var _noise_i: float = 0.0

func _ready() -> void:
	# 不抢镜头,只在原有 position 上叠加偏移
	pass

func add_trauma(amount: float) -> void:
	if GameManager.reduce_motion:
		return
	trauma = clamp(trauma + amount, 0.0, 1.0)

func _process(delta: float) -> void:
	if trauma <= 0.0:
		offset = Vector2.ZERO
		rotation = 0.0
		return
	# 偏移: 平方关系(小震平滑,大震激烈)
	var t2 := trauma * trauma
	var t := _noise_i
	offset = Vector2(
		max_offset.x * t2 * (sin(t * 1.7) + cos(t * 2.3)) * 0.5,
		max_offset.y * t2 * (cos(t * 1.3) + sin(t * 2.7)) * 0.5
	)
	rotation = max_rotation * t2 * sin(t * 1.1)
	_noise_i += noise_speed * delta
	trauma = max(0.0, trauma - decay * delta)
