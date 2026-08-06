extends Node
## 统一管理场景跳转，封装带参数传递的场景切换逻辑。

const BOOT := "res://scenes/boot.tscn"
const MAIN_MENU := "res://scenes/main_menu.tscn"
const LEVEL_SELECT := "res://scenes/level_select.tscn"
const RESULT_SCREEN := "res://scenes/result_screen.tscn"

## 结算面板读取的临时数据（避免跨场景传参需要额外的单例字段）。
var pending_result: Dictionary = {}

func go_to_main_menu() -> void:
	_change_scene_deferred(MAIN_MENU)

func go_to_level_select() -> void:
	_change_scene_deferred(LEVEL_SELECT)

func go_to_level(level_resource_path: String) -> void:
	GameManager.current_level_path = level_resource_path
	_change_scene_deferred("res://scenes/level.tscn")

func go_to_result(victory: bool, stars: int, level_data: LevelData) -> void:
	pending_result = {
		"victory": victory,
		"stars": stars,
		"level_id": level_data.level_id if level_data else "",
		"next_level_id": level_data.next_level_id if level_data else "",
	}
	_change_scene_deferred(RESULT_SCREEN)

## 场景切换必须延迟到当前帧的节点增删操作完成后执行，
## 否则在 _ready() 里直接跳转会触发 "Parent node is busy" 报错。
func _change_scene_deferred(path: String) -> void:
	get_tree().paused = false
	get_tree().call_deferred("change_scene_to_file", path)
