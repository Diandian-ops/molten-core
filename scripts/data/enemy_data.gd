extends Resource
## 敌人类型的数值定义，策划可在编辑器中创建 .tres 资源实例来配置。
## v0.3.0 扩展: 暴击 / Boss 多阶段
class_name EnemyData

const BossPhase = preload("res://scripts/data/boss_phase.gd")

@export var id: String = "enemy_id"
@export var display_name: String = "灼奴"
@export var max_health: float = 20.0
@export var move_speed: float = 80.0
@export var armor: float = 0.0
@export var currency_reward: int = 5
@export var damage_to_core: int = 1
@export var scene: PackedScene

# === 暴击抗性 (0..1, 越大越不容易被暴击) ===
@export var crit_resistance: float = 0.0

# === 视觉 ===
@export var icon: Texture2D
@export var scale: float = 1.0
@export var tint: Color = Color.WHITE

# === Boss ===
@export var is_boss: bool = false
@export var boss_phases: Array[BossPhase] = []
