extends Control
## 全功能 HUD：包含左上角建塔晶币面板、右上角熔核生命/波次栏、建塔按键高亮/灰暗控制与 Inspector 控制台。
class_name HUD

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

@export var available_towers: Array[TowerData] = []

var _current_slot: BuildSlot = null
var _game_speed: float = 1.0

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
		if tower.upgrade():
			AudioManager.play_sfx("ui_click")
			_refresh_inspector_info(tower)
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
		_game_speed = 1.0
	Engine.time_scale = _game_speed
	_update_speed_button_text()

func _update_speed_button_text() -> void:
	if speed_button:
		speed_button.text = "⏩ %.0fx 速度" % _game_speed
