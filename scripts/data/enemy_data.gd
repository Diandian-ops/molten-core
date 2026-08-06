extends Resource
## 敌人类型的数值定义，策划可在编辑器中创建 .tres 资源实例来配置。
class_name EnemyData

@export var id: String = "enemy_id"
@export var display_name: String = "灼奴"
@export var max_health: float = 20.0
@export var move_speed: float = 80.0
@export var armor: float = 0.0
@export var currency_reward: int = 5
@export var damage_to_core: int = 1
@export var scene: PackedScene
