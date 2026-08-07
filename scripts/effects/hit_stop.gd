extends Node
## 全局命中顿帧（hit-stop）：短暂压低 Engine.time_scale 制造"顿"的打击感。
## 速度安全：捕获当前 time_scale（含玩家 2x/3x）并在结束后还原，绝不破坏速度按钮设置。
## 节流：同一时刻只存在一个顿帧（MIN_INTERVAL > 最大顿帧时长），避免多命中叠加把倍速冲掉或造成持续卡顿。
## 无障碍：减弱动效(reduce_motion)时跳过。
## 用 autoload 而非 class_name：headless 解析环境下按名引用 class_name 全局名不可靠（见 ThemeConstants 同款处理）。

const MIN_INTERVAL := 0.09   # 两次顿帧最小真实间隔（秒），须大于最大顿帧时长以避免叠加
const FREEZE := 0.05          # 顿帧期间 time_scale（接近冻结但非零，避免 process_frame 异常）
var _last_time := -10.0

## real_duration：顿帧真实时长（秒，不随 time_scale 缩放）；freeze：顿帧期间 time_scale 值。
func trigger(real_duration := 0.05, freeze := FREEZE) -> void:
	if GameManager.reduce_motion:
		return
	if Engine.time_scale <= 0.0:
		return  # 已暂停/已冻结，跳过
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_time < MIN_INTERVAL:
		return  # 节流：上一个顿帧仍在进行
	_last_time = now
	var prev := Engine.time_scale
	Engine.time_scale = max(0.02, freeze)
	# 用真实帧计数还原（process_frame 不受 time_scale 缩放），约 real_duration 秒后恢复玩家原倍速
	var frames := int(ceil(real_duration * 60.0))
	for i in range(frames):
		await get_tree().process_frame
	Engine.time_scale = prev
