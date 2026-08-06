extends Node2D
## 关卡主控制器：全网格暗黑火山瓷砖地表、炽热熔岩运导轨、CanvasLayer HUD 渲染与波次防守调度。
class_name Level

const GROUND_TEXTURE = preload("res://assets/kenney_td/tiles/towerDefense_tile021.png")
const BossPhase = preload("res://scripts/data/boss_phase.gd")

@export var level_data: LevelData

@onready var core: Core = $Core
@onready var spawn_manager: Node = $SpawnManager
@onready var hud: HUD = $CanvasLayer/HUD
@onready var build_slots_container: Node = $BuildSlots
@onready var map_ground: Node2D = $MapGround
@onready var path_overlay: Node2D = $PathOverlay
@onready var effects_node: Node2D = $Effects

var _current_wave_index: int = -1
var _alive_enemies: int = 0
var _all_waves_spawned: bool = false
var _level_ended: bool = false
var _anim_time: float = 0.0
var _boss_phase_spawners: Dictionary = {}

func _ready() -> void:
	if level_data == null:
		var path: String = GameManager.current_level_path
		if path != "":
			level_data = load(path)
	if level_data == null:
		level_data = load("res://levels/level_01.tres")
	if level_data == null:
		push_error("Level: 未提供 LevelData，无法初始化关卡。")
		return

	GameManager.reset_run(level_data.starting_currency, level_data.core_max_energy)
	GameManager.core_energy_changed.connect(_on_core_energy_changed)

	if core:
		core.global_position = level_data.core_position
		core.setup(level_data.core_max_energy)
		core.add_to_group("core")
		core.energy_depleted.connect(_on_core_depleted)

	_setup_build_slots()
	_init_map_ground()

	if hud and hud.has_method("setup"):
		hud.setup(level_data)

	if spawn_manager and spawn_manager.has_method("setup"):
		spawn_manager.setup(level_data, core.global_position)
		spawn_manager.enemy_spawned.connect(_on_enemy_spawned)
		spawn_manager.all_waves_completed.connect(_on_all_waves_completed)
		spawn_manager.wave_started.connect(_on_wave_started)
		spawn_manager.between_wave_started.connect(_on_between_wave_started)
		spawn_manager.start()

func _process(delta: float) -> void:
	_anim_time += delta
	if path_overlay:
		path_overlay.queue_redraw()

func _init_map_ground() -> void:
	if not map_ground:
		return
	# 清空现有子节点
	for c in map_ground.get_children():
		c.queue_free()
		
	# 在 1280x720 范围内铺设 20x12 块 64x64 瓷砖
	for x in range(20):
		for y in range(12):
			var tile := Sprite2D.new()
			tile.texture = GROUND_TEXTURE
			tile.position = Vector2(x * 64 + 32, y * 64 + 32)
			tile.modulate = Color(0.22, 0.18, 0.22) # 暗黑玄武岩底色
			map_ground.add_child(tile)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if hud:
			hud.close_all_menus()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if hud:
			hud.close_all_menus()

func draw_path_overlay() -> void:
	if not level_data or not path_overlay:
		return
		
	# 绘制每一个 Spawn 路线的熔岩路面与侧边边缘线
	for idx in range(level_data.spawn_points.size()):
		var path_pts := level_data.get_path_for_spawn(idx)
		if path_pts.size() >= 2:
			# 1. 绘制暗红熔岩粗管道底纹
			path_overlay.draw_polyline(path_pts, Color(0.5, 0.12, 0.05, 0.8), 34.0)
			# 2. 绘制炽热熔岩亮心管道
			path_overlay.draw_polyline(path_pts, Color(1.0, 0.45, 0.1, 0.95), 14.0)
			# 3. 绘制中心流光线
			path_overlay.draw_polyline(path_pts, Color(1.0, 0.85, 0.3, 0.9), 3.0)
			
			# 在路线上绘制方向脉冲粒子圈
			for p_idx in range(path_pts.size() - 1):
				var p1 := path_pts[p_idx]
				var p2 := path_pts[p_idx + 1]
				var progress := fmod(_anim_time * 0.9 + float(p_idx) * 0.3, 1.0)
				var pulse_pos := p1.lerp(p2, progress)
				path_overlay.draw_circle(pulse_pos, 5.0, Color(1.0, 0.9, 0.4, 0.9))

	# 绘制 Spawn 漩涡传送阵
	for spawn_pos in level_data.spawn_points:
		var r := 22.0 + sin(_anim_time * 4.0) * 3.0
		path_overlay.draw_circle(spawn_pos, r, Color(0.9, 0.2, 0.1, 0.4))
		path_overlay.draw_arc(spawn_pos, r + 4.0, 0, TAU, 24, Color(1.0, 0.5, 0.1, 0.9), 3.0)

func _setup_build_slots() -> void:
	if not build_slots_container:
		return
	for slot in build_slots_container.get_children():
		if slot is BuildSlot:
			slot.slot_selected.connect(_on_build_slot_selected)

func _on_build_slot_selected(slot: BuildSlot) -> void:
	if hud and hud.has_method("open_slot_menu"):
		hud.open_slot_menu(slot)
	# 玩家点击槽位后，如果该塔需要分支选择，弹出分支对话框
	if slot and is_instance_valid(slot.current_tower):
		var tw := slot.current_tower
		if tw.is_branch_choice_pending():
			_show_branch_dialog(tw)

func _show_branch_dialog(tower: Tower) -> void:
	if not hud or not hud.branch_dialog:
		return
	# 暂停游戏
	get_tree().paused = true
	hud.branch_dialog.show_for_tower(tower, tower.data.branch_a, tower.data.branch_b)
	hud.branch_dialog.visible = true
	# 选择后由 hud._on_branch_selected 处理，最后恢复
	if not hud.branch_dialog.branch_selected.is_connected(_on_branch_dialog_closed):
		hud.branch_dialog.branch_selected.connect(_on_branch_dialog_closed)

func _on_branch_dialog_closed(_id: String) -> void:
	if hud and hud.branch_dialog:
		hud.branch_dialog.visible = false
	get_tree().paused = false

func _on_enemy_spawned(enemy: Enemy) -> void:
	_alive_enemies += 1
	enemy.died.connect(_on_enemy_died)
	if enemy.is_boss() and enemy.data and not enemy.data.boss_phases.is_empty():
		# 监听 boss 阶段
		enemy.tree_exited.connect(_clear_boss_phase_spawner.bind(enemy))

func _on_boss_phase_passed(phase: BossPhase) -> void:
	# 阶段刷怪: 启动一个计时器周期性 spawn
	var timer := Timer.new()
	timer.wait_time = phase.spawn_interval
	timer.autostart = true
	timer.timeout.connect(func ():
		if not is_instance_valid(self) or _level_ended:
			timer.queue_free()
			return
		var enemy_data: EnemyData = _find_enemy_data_by_id(phase.spawn_enemy_id)
		if enemy_data and spawn_manager:
			# 使用第一个 spawn point
			if level_data and level_data.spawn_points.size() > 0:
				var entry := WaveEntry.new()
				entry.enemy_data = enemy_data
				entry.count = 1
				entry.spawn_point_index = 0
				# 直接调用 spawn_manager 内部? 避免访问私有,用 public spawn
				if spawn_manager.has_method("force_spawn"):
					spawn_manager.force_spawn(entry)
	)
	add_child(timer)
	_boss_phase_spawners[phase] = timer

func _clear_boss_phase_spawner(enemy: Enemy) -> void:
	for p in _boss_phase_spawners.keys():
		var t = _boss_phase_spawners[p]
		if is_instance_valid(t):
			t.queue_free()
	_boss_phase_spawners.clear()

func _find_enemy_data_by_id(id: String) -> EnemyData:
	# 简单查找:遍历 resources/enemies
	if id == "": return null
	for path in ["res://resources/enemies/enemy_slave.tres", "res://resources/enemies/enemy_shellguard.tres", "res://resources/enemies/enemy_rift_herald.tres"]:
		var d = load(path)
		if d and d is EnemyData and d.id == id:
			return d
	return null

func _on_enemy_died(_enemy: Enemy) -> void:
	_alive_enemies -= 1
	_check_victory()

func _on_wave_started(wave_index: int, total_waves: int) -> void:
	if hud and hud.has_method("update_wave_label"):
		hud.update_wave_label(wave_index + 1, total_waves)
	if hud and hud.has_method("clear_next_wave_countdown"):
		hud.clear_next_wave_countdown()

func _on_between_wave_started(next_index: int, delay: float) -> void:
	if hud and hud.has_method("show_next_wave_countdown"):
		hud.show_next_wave_countdown(next_index, delay)

func _on_all_waves_completed() -> void:
	_all_waves_spawned = true
	_check_victory()

func _check_victory() -> void:
	if _level_ended:
		return
	if _all_waves_spawned and _alive_enemies <= 0:
		_end_level(true)

func _on_core_energy_changed(current: int, _max_value: int) -> void:
	if current <= 0:
		_on_core_depleted()

func _on_core_depleted() -> void:
	_end_level(false)

func _end_level(victory: bool) -> void:
	if _level_ended:
		return
	_level_ended = true
	get_tree().paused = true
	var stars: int = 0
	if victory:
		stars = level_data.calculate_stars(GameManager.core_energy)
		GameManager.complete_level(level_data.level_id, stars, level_data.next_level_id)
	SceneRouter.go_to_result(victory, stars, level_data)
