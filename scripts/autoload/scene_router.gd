extends Node
## 统一管理场景跳转，封装带参数传递的场景切换逻辑。

const BOOT := "res://scenes/boot.tscn"
const MAIN_MENU := "res://scenes/main_menu.tscn"
const LEVEL_SELECT := "res://scenes/level_select.tscn"
const RESULT_SCREEN := "res://scenes/result_screen.tscn"
const STORY_LOG := "res://scenes/ui/story_log.tscn"

## 结算面板读取的临时数据（避免跨场景传参需要额外的单例字段）。
var pending_result: Dictionary = {}

func go_to_main_menu() -> void:
	_change_scene_deferred(MAIN_MENU)

func go_to_level_select() -> void:
	_change_scene_deferred(LEVEL_SELECT)

func go_to_story_log() -> void:
	_change_scene_deferred(STORY_LOG)

func go_to_level(level_resource_path: String) -> void:
	GameManager.current_level_path = level_resource_path
	_change_scene_deferred("res://scenes/level.tscn")

func go_to_result(victory: bool, stars: int, level_data: LevelData, reached_wave: int = 0, leaked: int = 0) -> void:
	pending_result = {
		"victory": victory,
		"stars": stars,
		"level_id": level_data.level_id if level_data else "",
		"next_level_id": level_data.next_level_id if level_data else "",
		"reached_wave": reached_wave,
		"leaked": leaked,
	}
	_change_scene_deferred(RESULT_SCREEN)

## 场景切换必须延迟到当前帧的节点增删操作完成后执行，
## 否则在 _ready() 里直接跳转会触发 "Parent node is busy" 报错。
## 统一过渡：当前场景上盖一层 ColorRect 淡出到黑，再切场（零资产，无需美术）。
## 进场的「亮」由目标场景各自的入场动效承担（主菜单呼吸 / 卡片错峰 / 结算缩放回弹）。
func _change_scene_deferred(path: String) -> void:
	get_tree().paused = false
	# 场景切换通用过渡音（whoosh）；缺资产时为无害空操作。
	AudioManager.play_sfx("whoosh")

	if GameManager.reduce_motion or get_tree().current_scene == null:
		get_tree().call_deferred("change_scene_to_file", path)
		return

	var root := get_tree().current_scene
	var cover := ColorRect.new()
	cover.color = Color(0, 0, 0, 0)
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	cover.z_index = 4096
	root.add_child(cover)
	var tw := root.create_tween()
	tw.tween_property(cover, "color:a", 1.0, 0.22).set_ease(Tween.EASE_IN)
	# 切场回调：change_scene_to_file 会释放旧场景（含本 cover），故无残留遮罩。
	tw.tween_callback(get_tree().call_deferred.bind("change_scene_to_file", path))
