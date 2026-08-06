extends Node2D
## 路径覆盖图层：专门在 Background 上层渲染熔岩河道路与 Rift 传送阵。

@onready var level: Level = get_parent() as Level

func _draw() -> void:
	if is_instance_valid(level) and level.has_method("draw_path_overlay"):
		level.draw_path_overlay()
