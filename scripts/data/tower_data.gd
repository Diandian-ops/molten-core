extends Resource
## 守卫塔类型的数值定义，策划可在编辑器中创建 .tres 资源实例来配置。
class_name TowerData

@export var id: String = "tower_id"
@export var display_name: String = "熔火塔"
@export var description: String = ""
@export var cost: int = 50
@export var damage: float = 10.0
@export var attack_range: float = 150.0
@export var attack_interval: float = 1.0
## 0 = 单体攻击, 1 = 范围溅射
@export var splash_radius: float = 0.0
@export var slow_factor: float = 0.0
@export var slow_duration: float = 0.0
@export var base_upgrade_cost: int = 40
@export var damage_per_level: float = 5.0
@export var range_per_level: float = 20.0
@export var max_level: int = 3
@export var scene: PackedScene
@export var icon: Texture2D
