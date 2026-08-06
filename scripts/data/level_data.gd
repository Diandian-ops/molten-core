extends Resource
## 关卡数据：地图裂痕点、波次序列、初始资源、星级评价阈值。
class_name LevelData

@export var level_id: String = "level_01"
@export var display_name: String = "序章·熔炉苏醒"
@export var next_level_id: String = ""

@export var starting_currency: int = 100
@export var core_max_energy: int = 20

## 裂痕点（敌人生成点）的世界坐标列表，索引对应 WaveEntry.spawn_point_index
@export var spawn_points: Array[Vector2] = []
## 每一个 Spawn 点对应的多拐点路线，包含终点 core_position
@export var paths: Array[PackedVector2Array] = []
## 核心（熔核）在场景中的位置
@export var core_position: Vector2 = Vector2.ZERO

func get_path_for_spawn(index: int) -> PackedVector2Array:
	if index >= 0 and index < paths.size() and not paths[index].is_empty():
		return paths[index]
	var fallback := PackedVector2Array()
	if index >= 0 and index < spawn_points.size():
		fallback.append(spawn_points[index])
	fallback.append(core_position)
	return fallback

@export var waves: Array[WaveData] = []

## 星级评价：剩余能量百分比达到阈值时获得对应星数
@export var star_2_energy_ratio: float = 0.5
@export var star_3_energy_ratio: float = 0.8

func calculate_stars(remaining_energy: int) -> int:
	if remaining_energy <= 0:
		return 0
	var ratio := float(remaining_energy) / float(max(core_max_energy, 1))
	if ratio >= star_3_energy_ratio:
		return 3
	elif ratio >= star_2_energy_ratio:
		return 2
	return 1
