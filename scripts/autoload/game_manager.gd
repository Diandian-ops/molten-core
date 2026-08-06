extends Node
## 全局游戏状态管理：关卡进度、星级存档、跨场景传递的运行时数据。

signal currency_changed(new_amount: int)
signal core_energy_changed(current: int, max_value: int)

const SAVE_PATH := "user://molten_core_save.json"

## 总线名映射：settings 的 key → AudioServer 总线名。
const BUS_MAP := {"master": "Master", "sfx": "SFX", "music": "Music"}

var currency: int = 0
var core_energy: int = 0
var core_energy_max: int = 0

## 当前正在游玩的关卡资源路径，由 LevelSelect 设置，Level 场景读取。
var current_level_path: String = ""

## key: level_id (String) -> value: 已获得的最高星级 (int, 0~3)
var level_stars: Dictionary = {}
## 已解锁的关卡 id 列表，序章关卡默认解锁。
var unlocked_levels: Array = ["level_01"]

## 音频设置：线性音量 0.0~1.0，key 见 BUS_MAP。
var settings: Dictionary = {"master": 1.0, "sfx": 1.0, "music": 1.0}

func _ready() -> void:
	load_progress()

func reset_run(starting_currency: int, starting_energy: int) -> void:
	currency = starting_currency
	core_energy_max = starting_energy
	core_energy = starting_energy
	currency_changed.emit(currency)
	core_energy_changed.emit(core_energy, core_energy_max)

func add_currency(amount: int) -> void:
	currency += amount
	currency_changed.emit(currency)

func spend_currency(amount: int) -> bool:
	if currency < amount:
		return false
	currency -= amount
	currency_changed.emit(currency)
	return true

func damage_core(amount: int) -> void:
	core_energy = max(0, core_energy - amount)
	core_energy_changed.emit(core_energy, core_energy_max)

## v0.3.0: 熔核血量由 Core 节点自管, 这里仅同步给 UI.
func set_core_energy(current: int, max_value: int) -> void:
	core_energy = current
	core_energy_max = max_value
	core_energy_changed.emit(core_energy, core_energy_max)

func is_core_destroyed() -> bool:
	return core_energy <= 0

func complete_level(level_id: String, stars: int, next_level_id: String) -> void:
	var prev: int = level_stars.get(level_id, 0)
	level_stars[level_id] = max(prev, stars)
	if next_level_id != "" and not unlocked_levels.has(next_level_id):
		unlocked_levels.append(next_level_id)
	save_progress()

func is_level_unlocked(level_id: String) -> bool:
	return unlocked_levels.has(level_id)

func get_stars_for(level_id: String) -> int:
	return level_stars.get(level_id, 0)

func get_volume(bus: String) -> float:
	return settings.get(bus, 1.0) as float

## 线性音量(0~1) → 分贝。手算避免依赖特定 Godot 版本的 AudioServer 静态方法。
static func linear_to_volume_db(linear: float) -> float:
	if linear <= 0.0001:
		return -80.0
	return 20.0 * log(linear) / log(10.0)

## 设置某总线音量（线性 0~1），实时生效并持久化。
func set_volume(bus: String, linear: float) -> void:
	var v := clampf(linear, 0.0, 1.0)
	settings[bus] = v
	var bus_name: String = BUS_MAP.get(bus, "Master")
	AudioManager.set_bus_volume(bus_name, linear_to_volume_db(v))
	save_progress()

func save_progress() -> void:
	var data := {
		"level_stars": level_stars,
		"unlocked_levels": unlocked_levels,
		"settings": settings,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	if parsed.has("level_stars"):
		level_stars = parsed["level_stars"]
	if parsed.has("unlocked_levels"):
		unlocked_levels = parsed["unlocked_levels"]
	if parsed.has("settings") and typeof(parsed["settings"]) == TYPE_DICTIONARY:
		var s: Dictionary = parsed["settings"]
		for key in BUS_MAP.keys():
			if s.has(key) and typeof(s[key]) == TYPE_FLOAT:
				settings[key] = s[key]
