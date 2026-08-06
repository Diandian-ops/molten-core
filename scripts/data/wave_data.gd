extends Resource
## 一个"波次"：包含若干条生成指令（WaveEntry），以及本波与下一波的间隔。
class_name WaveData

@export var entries: Array[WaveEntry] = []
## 本波所有敌人生成完成后，到下一波开始前的等待时间（秒）
@export var delay_after: float = 3.0
