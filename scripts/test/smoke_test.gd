extends Node
## 无头玩法冒烟测试（日常开发用）。
## 用法：临时把 project.godot 的 run/main_scene 指向本场景后，
##   godot --headless --path . 运行，捕获 stderr 判断有无运行时脚本错误。
## 覆盖：关卡初始化、波次自动开打、建塔（货币/建造/索敌）、敌人生成/移动/受击/
##       掉落、Boss 生成与阶段刷怪、熔核受击、关卡结束与结算场景切换。

func _ready() -> void:
	# 先跑一帧，确保 autoload 与当前场景环境就绪
	await get_tree().process_frame

	# 1) 实例化第 1 关（Level._ready 会自动 reset_run + start 波次）
	var level_scene: PackedScene = load("res://scenes/level.tscn")
	if level_scene == null:
		push_error("SMOKE_TEST: 无法加载 level.tscn")
		get_tree().quit(1)
		return
	var level = level_scene.instantiate()
	get_tree().root.add_child(level)

	# 等关卡 _ready 完成
	await get_tree().process_frame
	await get_tree().process_frame

	if not (level is Level):
		push_error("SMOKE_TEST: 关卡实例类型异常，期望 Level")
		get_tree().quit(1)
		return

	# 2) 遍历所有建造槽放塔，循环使用 3 种塔，确保路径附近有火力覆盖
	GameManager.add_currency(99999)
	var slots: Array = []
	if level.has_node("BuildSlots"):
		for c in level.get_node("BuildSlots").get_children():
			if c is BuildSlot:
				slots.append(c)
	var tower_paths := [
		"res://resources/towers/tower_flame.tres",
		"res://resources/towers/tower_shock.tres",
		"res://resources/towers/tower_crystal.tres",
	]
	var placed := 0
	for i in range(slots.size()):
		var td = load(tower_paths[i % tower_paths.size()])
		if td == null:
			continue
		slots[i].build_tower(td)
		placed += 1

	# 3) 强制刷一波普通敌人 + 一个 Boss，覆盖敌人移动/受击/Boss 路径
	var sm = level.get_node_or_null("SpawnManager")
	if sm != null and sm.has_method("force_spawn"):
		var entry := WaveEntry.new()
		entry.enemy_data = load("res://resources/enemies/enemy_slave.tres")
		entry.count = 8
		entry.spawn_point_index = 0
		sm.force_spawn(entry)

		var boss_entry := WaveEntry.new()
		boss_entry.enemy_data = load("res://resources/enemies/boss_lava_golem.tres")
		boss_entry.count = 1
		boss_entry.spawn_point_index = 0
		sm.force_spawn(boss_entry)

	# 4) 直接触发一次塔开火→弹道→命中链路；并直接触发 Boss 阶段刷怪逻辑
	await get_tree().process_frame
	var enemies := get_tree().get_nodes_in_group("enemies")
	var tw: Tower = null
	for c in level.get_node("BuildSlots").get_children():
		if c is BuildSlot and c.current_tower != null:
			tw = c.current_tower
			break
	if tw != null and enemies.size() > 0:
		tw._fire_at(enemies[0])
	if sm != null:
		var boss_data = load("res://resources/enemies/boss_lava_golem.tres")
		if boss_data != null and boss_data.boss_phases.size() > 0:
			level._on_boss_phase_passed(boss_data.boss_phases[0])

	print("SMOKE_TEST_OK: level=%s towers_placed=%d enemies_group=%d" % [
		level.name, placed, get_tree().get_nodes_in_group("enemies").size()])

	# 5) 周期性打印状态（存活敌人 / 熔核能量 / 货币 / Boss 存活），作为游戏持续推进的硬证据
	var status_timer := get_tree().create_timer(4.0)
	status_timer.timeout.connect(func():
		var alive := get_tree().get_nodes_in_group("enemies").size()
		var boss_alive := false
		for e in get_tree().get_nodes_in_group("enemies"):
			if e is Enemy and e.is_boss():
				boss_alive = true
		print("SMOKE_STATUS: alive_enemies=%d core_energy=%d currency=%d boss_alive=%s" % [
			alive, GameManager.core_energy, GameManager.currency, str(boss_alive)])
	)

	# 6) 运行约 26s 后主动退出（若未被关卡结束的 pause 卡住）
	var quit_timer := get_tree().create_timer(26.0)
	quit_timer.timeout.connect(func():
		print("SMOKE_DONE")
		get_tree().quit()
	)
