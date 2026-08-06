extends Node
## 启动场景：预留初始化逻辑（比如后续加载存档、检测平台），完成后跳转主菜单。

func _ready() -> void:
	SceneRouter.go_to_main_menu()
