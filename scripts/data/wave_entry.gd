extends Resource
## 单条"生成指令"：在某个延迟后，从指定裂痕点生成一批某类型敌人。
class_name WaveEntry

@export var enemy_data: EnemyData
@export var spawn_point_index: int = 0
@export var count: int = 1
@export var interval: float = 0.5
## 相对于本波开始的延迟（秒）
@export var start_delay: float = 0.0
