extends Resource
## 守卫塔类型的数值定义，策划可在编辑器中创建 .tres 资源实例来配置。
## v0.3.0 扩展: 技能 + 升级分支树
class_name TowerData

# === 基础 ===
@export var id: String = "tower_id"
@export var display_name: String = "熔火塔"
@export var description: String = ""
@export var cost: int = 50

# === 攻击 ===
@export var damage: float = 10.0
@export var attack_range: float = 150.0
@export var attack_interval: float = 1.0
@export var splash_radius: float = 0.0
@export var slow_factor: float = 0.0
@export var slow_duration: float = 0.0

# === 升级 (线性 Lv1->max_level) ===
@export var base_upgrade_cost: int = 40
@export var damage_per_level: float = 7.0
@export var range_per_level: float = 24.0
@export var max_level: int = 3

# === 主动技能 (v0.3.0) ===
@export var skill_name: String = ""
@export var skill_description: String = ""
@export var skill_cost: int = 50
@export var skill_cooldown: float = 15.0
@export var skill_radius: float = 0.0     # >0 圆形范围
@export var skill_cone_angle: float = 0.0 # >0 扇形 (度), 0=圆形
@export var skill_damage: int = 0
@export var skill_slow: float = 0.0       # 0..1
@export var skill_slow_duration: float = 0.0
@export var skill_stun: float = 0.0       # 秒

# === 升级分支 (v0.3.0) ===
## level==2 时弹选择对话框,玩家选 a 或 b
## 选完后引用分支的 TowerData 替换自己
@export var branch_a: TowerData = null
@export var branch_b: TowerData = null
@export var has_branch: bool = false   # true 表示 Lv2 时弹出分支

# === 资源 ===
@export var scene: PackedScene
@export var icon: Texture2D
@export var skill_icon: Texture2D
