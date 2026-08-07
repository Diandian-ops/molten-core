extends Node
## 轻量本地遥测：仅客观指标，落盘 user://telemetry/*.json，不联网。
## 用于 level_01 playtest 采集建塔决策 / 经济爬升 / 结局，佐证新手友好三件套的 A/B/C 信号。
## 所有文件操作均做错误检查，headless 下也不崩（写失败仅 warning，绝不抛错）。

const TELEMETRY_DIR := "user://telemetry"

var _events: Array = []
var _meta: Dictionary = {}
var _start_ms: int = 0
var _level_id: String = ""

## 开局清空并打点：记录关卡 id 与起始时间戳（内部统一算相对秒与总时长）。
func reset(level_id: String) -> void:
	_events = []
	_level_id = level_id
	_start_ms = Time.get_ticks_msec()
	_meta = {
		"level_id": level_id,
		"engine_version": "4.7.1",
		"schema": 1,
	}

func _now() -> float:
	return float(Time.get_ticks_msec() - _start_ms) / 1000.0

func log_event(type: String, data: Dictionary = {}) -> void:
	var entry := {"t": _now(), "type": type}
	for k in data.keys():
		entry[k] = data[k]
	_events.append(entry)

## 建塔决策：是否看过射程预览、悬停切换次数（反映预览是否被利用）。
func log_build(tower_id: String, saw_preview: bool, hover_switches: int) -> void:
	log_event("build", {"tower": tower_id, "saw_preview": saw_preview, "hover_switches": hover_switches})

## 每波快照：累计漏怪数与当时晶币（用于画经济爬升曲线，验证漏怪安慰是否够花）。
func log_wave(wave_index: int, leaked: int, currency: int) -> void:
	log_event("wave_snapshot", {"wave": wave_index + 1, "leaked_total": leaked, "currency": currency})

## 加速 / 暂停使用（反映玩家是否靠 2x/3x 跳过空窗或焦虑）。
func log_speed_change(speed: float) -> void:
	log_event("speed", {"speed": speed})

func log_pause(paused: bool) -> void:
	log_event("pause", {"paused": paused})

## 漏怪（突破熔核）：记录造成的伤害与剩余核心血量。
func log_leak(amount: int, core_hp: int) -> void:
	log_event("leak", {"damage": amount, "core_hp": core_hp})

## 结局：胜利 / 星级 / 到达波次。总时长由 flush 统一算。
func log_outcome(victory: bool, stars: int, reached_wave: int) -> void:
	log_event("outcome", {"victory": victory, "stars": stars, "reached_wave": reached_wave})

## 落盘：写到 user://telemetry/<level_id>_<时间戳>.json。
## 仅在 SceneRouter.go_to_result（统一结局出口）调用，任何通关/战败都落盘。
func flush() -> void:
	if _level_id == "":
		return
	var payload := {
		"meta": _meta,
		"duration_sec": _now(),
		"events": _events,
	}
	var dir := DirAccess.open("user://")
	if dir == null:
		push_warning("Telemetry: 无法打开 user://，跳过落盘。")
		return
	var dir_err := dir.make_dir_recursive("telemetry")
	if dir_err != OK:
		push_warning("Telemetry: 无法创建目录 telemetry (err=%d)，跳过落盘。" % dir_err)
		return
	var stamp := Time.get_datetime_string_from_system(false)\
		.replace(" ", "_").replace(":", "-")
	var fname := "%s_%s.json" % [_level_id, stamp]
	var path := TELEMETRY_DIR + "/" + fname
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_warning("Telemetry: 无法写入 %s，跳过落盘。" % path)
		return
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
