extends Node
## 波次生成管理器：按 LevelData.waves 顺序生成敌人，通知 Level 波次进度。
class_name SpawnManager

signal enemy_spawned(enemy: Enemy)
signal wave_started(wave_index: int, total_waves: int)
signal all_waves_completed
## 两波之间的间隔开始：next_index 为下一波的 0 基索引，delay 为该间隔秒数。
signal between_wave_started(next_index: int, delay: float)
## 某一波的所有敌人“生成完毕”（尚未被击杀）——供 HUD 判断波次清空庆祝。
signal wave_spawn_completed(wave_index: int)

var _level_data: LevelData
var _core_position: Vector2
var _enemy_container: Node
## 当前正在执行、尚未完成的生成协程数量（同一波内多条指令并发运行）。
var _active_entries: int = 0

func setup(level_data: LevelData, core_position: Vector2) -> void:
	_level_data = level_data
	_core_position = core_position
	_enemy_container = get_tree().current_scene.get_node_or_null("Enemies")
	if _enemy_container == null:
		_enemy_container = self

func start() -> void:
	_run_waves()

func _run_waves() -> void:
	var total := _level_data.waves.size()
	for i in range(total):
		AudioManager.play_sfx("wave_start")
		wave_started.emit(i, total)
		await _run_single_wave(_level_data.waves[i])
		wave_spawn_completed.emit(i)
		if i < total - 1:
			between_wave_started.emit(i + 1, _level_data.waves[i].delay_after)
		await get_tree().create_timer(_level_data.waves[i].delay_after).timeout
	all_waves_completed.emit()

func _run_single_wave(wave: WaveData) -> void:
	if wave.entries.is_empty():
		return
	_active_entries = wave.entries.size()
	for entry in wave.entries:
		_run_entry(entry)
	while _active_entries > 0:
		await get_tree().process_frame

func _run_entry(entry: WaveEntry) -> void:
	if entry.start_delay > 0.0:
		await get_tree().create_timer(entry.start_delay).timeout
	for i in range(entry.count):
		_spawn_enemy(entry)
		if i < entry.count - 1:
			await get_tree().create_timer(entry.interval).timeout
	_active_entries -= 1

func force_spawn(entry: WaveEntry) -> void:
	for i in range(entry.count):
		_spawn_enemy(entry)
		if i < entry.count - 1 and entry.interval > 0.0:
			await get_tree().create_timer(entry.interval).timeout

func _spawn_enemy(entry: WaveEntry) -> void:
	if entry.enemy_data == null or entry.enemy_data.scene == null:
		return
	if entry.spawn_point_index < 0 or entry.spawn_point_index >= _level_data.spawn_points.size():
		return
	var spawn_pos: Vector2 = _level_data.spawn_points[entry.spawn_point_index]
	var waypoints: PackedVector2Array = _level_data.get_path_for_spawn(entry.spawn_point_index)
	var enemy: Enemy = entry.enemy_data.scene.instantiate()
	_enemy_container.add_child(enemy)
	enemy.global_position = spawn_pos
	enemy.setup(entry.enemy_data, _core_position, waypoints)
	enemy_spawned.emit(enemy)
