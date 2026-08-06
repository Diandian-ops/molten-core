extends Resource
## Boss 阶段配置: 当血量降到 hp_threshold 时触发。
class_name BossPhase

@export var hp_threshold: float = 0.5      # 血量比例
@export var speed_mult: float = 1.0        # 狂暴速度倍率
@export var spawn_interval: float = 0.0    # >0 时周期性刷怪
@export var spawn_enemy_id: String = ""    # 刷哪种敌人
@export var skill_name: String = ""        # 阶段技能名(用于展示)
@export var triggered: bool = false
