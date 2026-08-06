extends Control
## 全功能 HUD：包含左上角建塔晶币面板、右上角熔核生命/波次栏、建塔按键高亮/灰暗控制与 Inspector 控制台。
class_name HUD

const ParticleBurst = preload("res://scripts/effects/particle_burst.gd")
const FlashBurst = preload("res://scripts/effects/flash_burst.gd")

@onready var currency_label: Label = $TopRightPanel/Margin/HBoxContainer/CurrencyLabel
@onready var wave_label: Label = $TopRightPanel/Margin/HBoxContainer/WaveLabel
@onready var energy_bar: ProgressBar = $TopRightPanel/Margin/HBoxContainer/EnergyContainer/EnergyBar
@onready var energy_label: Label = $TopRightPanel/Margin/HBoxContainer/EnergyContainer/EnergyBar/EnergyLabel
@onready var speed_button: Button = $TopRightPanel/Margin/HBoxContainer/SpeedButton

@onready var build_menu: PanelContainer = $BuildMenu
@onready var build_menu_buttons: VBoxContainer = $BuildMenu/Margin/Layout/VBoxContainer

@onready var inspector_menu: PanelContainer = $InspectorMenu
@onready var tower_name_label: Label = $InspectorMenu/Margin/VBoxContainer/Header/TowerNameLabel
@onready var tower_stats_label: Label = $InspectorMenu/Margin/VBoxContainer/StatsLabel
@onready var upgrade_button: Button = $InspectorMenu/Margin/VBoxContainer/UpgradeButton
@onready var sell_button: Button = $InspectorMenu/Margin/VBoxContainer/SellButton
@onready var skill_button: Button = $InspectorMenu/Margin/VBoxContainer/SkillButton
@onready var skill_cd_label: Label = $InspectorMenu/Margin/VBoxContainer/SkillCDLabel

# 熔核技能底栏
@onready var core_skills_bar: HBoxContainer = $CoreSkillsBar
@onready var heal_button: Button = $CoreSkillsBar/HealButton
@onready var shock_button: Button = $CoreSkillsBar/ShockButton
@onready var shield_button: Button = $CoreSkillsBar/ShieldButton
@onready var heal_cd_label: Label = $CoreSkillsBar/HealButton/CDLabel
@onready var shock_cd_label: Label = $CoreSkillsBar/ShockButton/CDLabel
@onready var shield_cd_label: Label = $CoreSkillsBar/ShieldButton/CDLabel

# 濒死红边 + 心跳层
@onready var danger_overlay: ColorRect = $DangerOverlay
@onready var branch_dialog = $BranchSelectDialog

# 暂停控制（运行时动态构建，避免改动 .tscn）
@onready var _top_bar: HBoxContainer = $TopRightPanel/Margin/HBoxContainer
var _pause_button: Button
var _pause_overlay: Control

# 下一波倒计时提示（运行时动态构建）
var _next_wave_index: int = 0
var _next_wave_time: float = 0.0
var _next_wave_active: bool = false
var _wave_hint: Control
var _wave_hint_label: Label

@export var available_towers: Array[TowerData] = []

var _current_slot: BuildSlot = null
var _game_speed: float = 1.0
var _heartbeat_timer: float = 0.0
var _danger_pulse: float = 0.0

func _ready() -> void:
	GameManager.currency_changed.connect(_on_currency_changed)
	GameManager.core_energy_changed.connect(_on_energy_changed)
	_on_currency_changed(GameManager.currency)
	_on_energy_changed(GameManager.core_energy, GameManager.core_energy_max)
	
	if build_menu:
		build_menu.visible = false
		build_menu.gui_input.connect(_on_menu_gui_input)
	if inspector_menu:
		inspector_menu.visible = false
		inspector_menu.gui_input.connect(_on_menu_gui_input)

	if speed_button:
		speed_button.pressed.connect(_on_speed_button_pressed)
		_update_speed_button_text()
		
	if upgrade_button:
		upgrade_button.pressed.connect(_on_upgrade_pressed)
	if sell_button:
		sell_button.pressed.connect(_on_sell_pressed)
	if skill_button:
		skill_button.pressed.connect(_on_skill_pressed)
		
	# 熔核技能
	for b in [heal_button, shock_button, shield_button]:
		if b:
			b.pressed.connect(_on_core_skill_pressed.bind(b.name))
	if branch_dialog:
		branch_dialog.visible = false
		branch_dialog.branch_selected.connect(_on_branch_selected)
		
	if danger_overlay:
		danger_overlay.color = Color(1.0, 0.0, 0.0, 0.0)
		danger_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_setup_pause_ui()
	_setup_wave_hint()
	_populate_build_menu()

func _on_menu_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		get_viewport().set_input_as_handled()

func setup(_level_data: LevelData) -> void:
	pass

func _populate_build_menu() -> void:
	if not build_menu_buttons:
		return
	for child in build_menu_buttons.get_children():
		child.queue_free()
		
	for tower_data in available_towers:
		var btn := Button.new()
		var tag := ""
		var detail := ""
		
		if tower_data.id == "tower_flame" or "熔火" in tower_data.display_name:
			tag = "【单体高伤 · 速射点杀】"
			detail = "伤害: %.0f | 射程: %.0f" % [tower_data.damage, tower_data.attack_range]
		elif tower_data.id == "tower_shock" or "震波" in tower_data.display_name:
			tag = "【范围AOE · 破防减速】"
			detail = "伤害: %.0f | 溅射: %.0f" % [tower_data.damage, tower_data.splash_radius]
		elif tower_data.id == "tower_crystal" or "熔晶" in tower_data.display_name:
			tag = "【远距控场 · 极寒冰霜】"
			detail = "射程: %.0f | 减速: %.0f%%" % [tower_data.attack_range, tower_data.slow_factor * 100.0]
		else:
			tag = "【防御塔】"
			detail = "伤害: %.0f" % tower_data.damage

		btn.text = "%s (💎 %d)\n%s\n%s" % [tower_data.display_name, tower_data.cost, tag, detail]
		btn.icon = tower_data.icon
		btn.expand_icon = true
		btn.custom_minimum_size = Vector2(230, 68)
		btn.pressed.connect(_on_tower_button_pressed.bind(tower_data))
		build_menu_buttons.add_child(btn)

func open_slot_menu(slot: BuildSlot) -> void:
	close_all_menus()
	_current_slot = slot
	
	if slot.occupied and is_instance_valid(slot.current_tower):
		_show_inspector_menu(slot)
	else:
		_show_build_menu(slot)

func _show_build_menu(slot: BuildSlot) -> void:
	if not build_menu:
		return
	build_menu.visible = true
	var min_s := build_menu.get_combined_minimum_size()
	var pos := slot.global_position + Vector2(20, -60)
	var viewport_size := get_viewport_rect().size
	pos.x = clamp(pos.x, 20.0, viewport_size.x - min_s.x - 20.0)
	pos.y = clamp(pos.y, 60.0, viewport_size.y - min_s.y - 20.0)
	build_menu.global_position = pos
	
	# 更新标题提示当前持有的晶币/建塔能量
	var title_lbl := build_menu.get_node_or_null("Margin/Layout/TitleLabel") as Label
	if title_lbl:
		title_lbl.text = "🛠️ 构造防御塔 (持有 💎 %d)" % GameManager.currency

	_update_build_buttons_availability()

func _update_build_buttons_availability() -> void:
	if not build_menu_buttons:
		return
	var idx := 0
	for child in build_menu_buttons.get_children():
		if child is Button and idx < available_towers.size():
			var tdata := available_towers[idx]
			var btn := child as Button
			var has_enough := (GameManager.currency >= tdata.cost)
			
			btn.disabled = not has_enough
			if has_enough:
				# 能量足够：亮黄/高亮显眼
				btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
			else:
				# 能量不足：灰暗变暗、半透明禁用感
				btn.modulate = Color(0.4, 0.4, 0.4, 0.5)
			idx += 1

func _show_inspector_menu(slot: BuildSlot) -> void:
	if not inspector_menu or not slot.current_tower:
		return
	var tower := slot.current_tower
	tower.set_range_visible(true)
	inspector_menu.visible = true
	
	var min_s := inspector_menu.get_combined_minimum_size()
	var pos := slot.global_position + Vector2(20, -80)
	var viewport_size := get_viewport_rect().size
	pos.x = clamp(pos.x, 20.0, viewport_size.x - min_s.x - 20.0)
	pos.y = clamp(pos.y, 60.0, viewport_size.y - min_s.y - 20.0)
	inspector_menu.global_position = pos
	
	_refresh_inspector_info(tower)

func _refresh_inspector_info(tower: Tower) -> void:
	if not tower:
		return
	if tower_name_label:
		tower_name_label.text = "%s (Lv.%d)" % [tower.data.display_name, tower.level]
	if tower_stats_label:
		tower_stats_label.text = "攻击力: %.1f\n射程: %.0f\n攻速: %.1fs/发" % [
			tower.get_current_damage(),
			tower.get_current_range(),
			tower.data.attack_interval
		]
	if upgrade_button:
		if tower.can_upgrade():
			var cost := tower.get_upgrade_cost()
			upgrade_button.text = "⬆️ 升级 (💎 %d)" % cost
			upgrade_button.disabled = (GameManager.currency < cost)
		else:
			upgrade_button.text = "★ 已达到最大等级"
			upgrade_button.disabled = true
	if sell_button:
		sell_button.text = "💰 出售 (+💎 %d)" % tower.get_sell_value()

func close_all_menus() -> void:
	if _current_slot and is_instance_valid(_current_slot.current_tower):
		_current_slot.current_tower.set_range_visible(false)
	_current_slot = null
	if build_menu:
		build_menu.visible = false
	if inspector_menu:
		inspector_menu.visible = false

func _on_tower_button_pressed(tower_data: TowerData) -> void:
	if _current_slot and GameManager.currency >= tower_data.cost:
		_current_slot.build_tower(tower_data)
	close_all_menus()

func _on_upgrade_pressed() -> void:
	if _current_slot and is_instance_valid(_current_slot.current_tower):
		var tower := _current_slot.current_tower
		# 分支选择优先
		if tower.is_branch_choice_pending():
			AudioManager.play_sfx("ui_click")
			_show_branch_dialog(tower)
			return
		if tower.upgrade():
			AudioManager.play_sfx("ui_click")
			_refresh_inspector_info(tower)
			GameManager.currency_changed.emit(GameManager.currency)

func _show_branch_dialog(tower: Tower) -> void:
	if not branch_dialog:
		return
	get_tree().paused = true
	branch_dialog.show_for_tower(tower, tower.data.branch_a, tower.data.branch_b)
	branch_dialog.visible = true
	if not branch_dialog.branch_selected.is_connected(_on_branch_dialog_closed):
		branch_dialog.branch_selected.connect(_on_branch_dialog_closed)

func _on_branch_dialog_closed(_id: String) -> void:
	branch_dialog.visible = false
	get_tree().paused = false
	if _current_slot and is_instance_valid(_current_slot.current_tower):
		_refresh_inspector_info(_current_slot.current_tower)
		GameManager.currency_changed.emit(GameManager.currency)

func _on_sell_pressed() -> void:
	if _current_slot:
		_current_slot.sell_tower()
		AudioManager.play_sfx("ui_click_2")
	close_all_menus()

func _on_currency_changed(amount: int) -> void:
	if currency_label:
		currency_label.text = "💎 可用晶币: %d" % amount
	if build_menu and build_menu.visible:
		_update_build_buttons_availability()
	if _current_slot and is_instance_valid(_current_slot.current_tower):
		_refresh_inspector_info(_current_slot.current_tower)

func _on_energy_changed(current: int, max_value: int) -> void:
	if energy_bar:
		energy_bar.max_value = max_value
		energy_bar.value = current
	if energy_label:
		var pct := (float(current) / float(max(1, max_value))) * 100.0
		energy_label.text = "%d / %d (%.0f%%)" % [current, max_value, pct]

func update_wave_label(current_wave: int, total_waves: int) -> void:
	if wave_label:
		wave_label.text = "🌊 波次 %d / %d" % [current_wave, total_waves]

func _on_speed_button_pressed() -> void:
	if _game_speed == 1.0:
		_game_speed = 2.0
	elif _game_speed == 2.0:
		_game_speed = 3.0
	else:
		_game_speed = 1.0
	Engine.time_scale = _game_speed
	_update_speed_button_text()

func _update_speed_button_text() -> void:
	if speed_button:
		speed_button.text = "⏩ %.0fx 速度" % _game_speed

func _setup_pause_ui() -> void:
	if _top_bar:
		_pause_button = Button.new()
		_pause_button.custom_minimum_size = Vector2(44, 30)
		_pause_button.text = "⏸️"
		_pause_button.tooltip_text = "暂停 / 继续"
		_pause_button.pressed.connect(_on_pause_pressed)
		_top_bar.add_child(_pause_button)

	# 全屏“已暂停”遮罩：拦截游戏世界点击，并提供继续按钮。
	_pause_overlay = Control.new()
	_pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_overlay.visible = false
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.5)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pause_overlay.add_child(bg)
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_pause_overlay.add_child(vbox)
	var lbl := Label.new()
	lbl.text = "⏸  已暂停"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 40)
	vbox.add_child(lbl)
	var resume := Button.new()
	resume.text = "▶️  继续游戏"
	resume.custom_minimum_size = Vector2(200, 48)
	resume.pressed.connect(_on_pause_pressed)
	vbox.add_child(resume)
	add_child(_pause_overlay)
	_update_pause_text()

func _on_pause_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	get_tree().paused = not get_tree().paused
	_update_pause_text()

func _update_pause_text() -> void:
	var paused := get_tree().paused
	if _pause_button:
		_pause_button.text = "▶️" if paused else "⏸️"
	if _pause_overlay:
		_pause_overlay.visible = paused

func _setup_wave_hint() -> void:
	_wave_hint = Control.new()
	_wave_hint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_wave_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wave_hint.visible = false
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	panel.add_theme_constant_override("margin_top", 10)
	_wave_hint.add_child(panel)
	_wave_hint_label = Label.new()
	_wave_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave_hint_label.add_theme_font_size_override("font_size", 22)
	_wave_hint_label.text = ""
	panel.add_child(_wave_hint_label)
	add_child(_wave_hint)

## 由 Level 转发 SpawnManager.between_wave_started：启动下一波倒计时显示。
func show_next_wave_countdown(next_index: int, delay: float) -> void:
	_next_wave_index = next_index
	_next_wave_time = max(delay, 0.0)
	_next_wave_active = true
	if _wave_hint:
		_wave_hint.visible = true
	_update_wave_hint()

## 新波次开始或关卡结束：清除倒计时提示。
func clear_next_wave_countdown() -> void:
	_next_wave_active = false
	if _wave_hint:
		_wave_hint.visible = false

func _update_wave_hint() -> void:
	if _wave_hint_label:
		_wave_hint_label.text = "⚔️ 第 %d 波将在 %.1f 秒后来袭" % [_next_wave_index + 1, max(_next_wave_time, 0.0)]

func _process(delta: float) -> void:
	# 下一波倒计时（受 time_scale 影响；暂停时 _process 停止，自然冻结）
	if _next_wave_active:
		_next_wave_time -= delta
		if _next_wave_time < 0.0:
			_next_wave_time = 0.0
		_update_wave_hint()

	# 塔技能状态刷新
	if _current_slot and is_instance_valid(_current_slot.current_tower):
		var tw := _current_slot.current_tower
		if skill_button:
			var can := tw.can_use_skill()
			skill_button.disabled = not can
			if tw.data.skill_name != "":
				skill_button.text = "⚡ %s (💎%d)" % [tw.data.skill_name, tw.data.skill_cost]
			else:
				skill_button.text = "(该塔无技能)"
				skill_button.disabled = true
			if skill_cd_label:
				if tw.get_skill_cooldown_remaining() > 0.0:
					skill_cd_label.text = "CD: %.1fs" % tw.get_skill_cooldown_remaining()
					skill_cd_label.visible = true
				else:
					skill_cd_label.visible = false
	# 熔核技能按钮
	_refresh_core_skill_buttons()
	# 濒死心跳 + 红边
	_update_danger(delta)

func _refresh_core_skill_buttons() -> void:
	var core := get_tree().get_first_node_in_group("core") as Core
	if not core:
		return
	_update_core_btn(heal_button, heal_cd_label, core, "heal", "💚 治愈")
	_update_core_btn(shock_button, shock_cd_label, core, "shock", "🌊 震波")
	_update_core_btn(shield_button, shield_cd_label, core, "shield", "🛡️ 护盾")

func _update_core_btn(btn: Button, cd_lbl: Label, core: Core, id: String, label: String) -> void:
	if not btn:
		return
	var can := core.can_use_skill(id)
	btn.disabled = not can
	btn.text = "%s (💎%d)" % [label, core.skill_cost(id)]
	if cd_lbl:
		var rem := core.get_skill_cd_remaining(id)
		if rem > 0.0:
			cd_lbl.text = "%.0fs" % rem
			cd_lbl.visible = true
		else:
			cd_lbl.visible = false

func _on_core_skill_pressed(btn_name: String) -> void:
	var core := get_tree().get_first_node_in_group("core") as Core
	if not core:
		return
	var id := "heal"
	if btn_name == "ShockButton": id = "shock"
	elif btn_name == "ShieldButton": id = "shield"
	core.use_skill(id)

func _on_skill_pressed() -> void:
	if _current_slot and is_instance_valid(_current_slot.current_tower):
		var tw := _current_slot.current_tower
		tw.use_skill()
		_refresh_inspector_info(tw)
		GameManager.currency_changed.emit(GameManager.currency)

func _on_branch_selected(branch_id: String) -> void:
	if not _current_slot or not is_instance_valid(_current_slot.current_tower):
		return
	var tw := _current_slot.current_tower
	tw.set_branch_choice(branch_id)
	var new_data: TowerData = tw.data.branch_a if branch_id == "a" else tw.data.branch_b
	if new_data:
		tw.transform_to(new_data)
		_refresh_inspector_info(tw)
		GameManager.currency_changed.emit(GameManager.currency)

func _update_danger(delta: float) -> void:
	var core := get_tree().get_first_node_in_group("core") as Core
	if not core or not danger_overlay:
		return
	var hp := core.get_hp()
	var max_hp := core.max_energy
	var ratio := float(hp) / float(max_hp) if max_hp > 0 else 1.0
	if ratio <= 0.2:
		if GameManager.reduce_motion:
			# 减弱动效：静态淡红边，不脉动、不播心跳音
			danger_overlay.color = Color(1.0, 0.0, 0.0, 0.18)
			_heartbeat_timer = 0.0
			return
		_danger_pulse += delta * 3.0
		var a := (sin(_danger_pulse) + 1.0) * 0.5 * 0.5
		danger_overlay.color = Color(1.0, 0.0, 0.0, a)
		_heartbeat_timer -= delta
		if _heartbeat_timer <= 0.0:
			AudioManager.play_sfx("heartbeat", -4.0, 1.0)
			_heartbeat_timer = 0.9
	else:
		_danger_pulse = 0.0
		danger_overlay.color = Color(1.0, 0.0, 0.0, 0.0)
		_heartbeat_timer = 0.0
