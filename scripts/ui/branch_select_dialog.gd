extends Control
## 分支选择对话框: 塔升到 Lv2 且有分支时弹出,玩家选 a/b 不可逆。
class_name BranchSelectDialog

signal branch_selected(branch_id: String)

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var left_btn: Button = $Panel/VBoxContainer/Body/Left
@onready var right_btn: Button = $Panel/VBoxContainer/Body/Right
@onready var left_desc: Label = $Panel/VBoxContainer/Body/Left/DescLabel
@onready var right_desc: Label = $Panel/VBoxContainer/Body/Right/DescLabel
@onready var left_icon: TextureRect = $Panel/VBoxContainer/Body/Left/Icon
@onready var right_icon: TextureRect = $Panel/VBoxContainer/Body/Right/Icon

var _tower: Tower = null

func show_for_tower(tower: Tower, branch_a: TowerData, branch_b: TowerData) -> void:
	_tower = tower
	visible = true
	if tower:
		title_label.text = "选择 %s 的进化方向 (不可逆)" % tower.data.display_name
	if branch_a:
		left_btn.text = branch_a.display_name
		left_desc.text = branch_a.description
		if branch_a.icon: left_icon.texture = branch_a.icon
	if branch_b:
		right_btn.text = branch_b.display_name
		right_desc.text = branch_b.description
		if branch_b.icon: right_icon.texture = branch_b.icon

func _on_left_pressed() -> void:
	AudioManager.play_sfx("branch_pick")
	branch_selected.emit("a")
	close()

func _on_right_pressed() -> void:
	AudioManager.play_sfx("branch_pick")
	branch_selected.emit("b")
	close()

func close() -> void:
	visible = false
