extends Node
## 全局音频管理 (Autoload).
## 12 个 CC0 音效通过 dictionary 缓存 AudioStreamPlayer 池.
## 公共 API: play_sfx(id) | play_music(id) | stop_music() | set_bus_volume(bus, db)

const SFX_PATHS := {
	"tower_shoot":    "res://assets/audio/sfx/tower_shoot.wav",
	"projectile_hit": "res://assets/audio/sfx/projectile_hit.wav",
	"enemy_kill":     "res://assets/audio/sfx/enemy_kill.wav",
	"tower_place":    "res://assets/audio/sfx/tower_place.wav",
	"tower_upgrade":  "res://assets/audio/sfx/tower_upgrade.wav",
	"core_damaged":   "res://assets/audio/sfx/core_damaged.wav",
	"core_destroyed": "res://assets/audio/sfx/core_destroyed.wav",
	"ui_click":       "res://assets/audio/sfx/ui_click.wav",
	"ui_click_2":     "res://assets/audio/sfx/ui_click_2.wav",
	"wave_start":     "res://assets/audio/sfx/wave_start.wav",
	"win":            "res://assets/audio/sfx/win.wav",
	"lose":           "res://assets/audio/sfx/lose.wav",
	# v0.3.0
	"heartbeat":      "res://assets/audio/sfx/heartbeat.wav",
	"critical_hit":   "res://assets/audio/sfx/critical_hit.wav",
	"boss_roar":      "res://assets/audio/sfx/boss_roar.wav",
	"tower_skill":    "res://assets/audio/sfx/tower_skill.wav",
	"core_skill":     "res://assets/audio/sfx/core_skill.wav",
	"branch_pick":    "res://assets/audio/sfx/branch_pick.wav",
	"whoosh":         "res://assets/audio/sfx/whoosh.wav",
	"boom":           "res://assets/audio/sfx/boom.wav",
}

# 每个 id 一个 4 个 player 的池,允许同帧多次重叠
const POOL_SIZE := 4
var _sfx_pool: Dictionary = {}      # { id: [AudioStreamPlayer, ...] }
var _sfx_index: Dictionary = {}     # 轮询索引
var _sfx_streams: Dictionary = {}   # { id: AudioStream } 懒加载缓存
var _music_player: AudioStreamPlayer
var _sfx_bus: String = "SFX"
var _music_bus: String = "Music"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 确保音频总线存在
	_ensure_bus(_sfx_bus)
	_ensure_bus(_music_bus)
	# 初始化音乐播放器
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = _music_bus
	add_child(_music_player)
	# 应用已保存的音量设置（GameManager 已在自身 _ready 中完成 load_progress）
	_apply_saved_volumes()

## 把关卡/设置的音量还原到对应总线。
func _apply_saved_volumes() -> void:
	for bus in GameManager.BUS_MAP.keys():
		var lin: float = GameManager.get_volume(bus)
		set_bus_volume(GameManager.BUS_MAP[bus], GameManager.linear_to_volume_db(lin))

func _ensure_bus(bus_name: String) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")

func _load_stream(id: String) -> AudioStream:
	if _sfx_streams.has(id):
		return _sfx_streams[id]
	if not SFX_PATHS.has(id):
		return null
	var stream: AudioStream = load(SFX_PATHS[id])
	if stream == null:
		push_warning("AudioManager: failed to load sfx '%s'" % id)
		return null
	_sfx_streams[id] = stream
	return stream

func _get_player(id: String) -> AudioStreamPlayer:
	if not SFX_PATHS.has(id):
		push_warning("AudioManager: unknown sfx id '%s'" % id)
		return null
	var stream := _load_stream(id)
	if stream == null:
		return null
	if not _sfx_pool.has(id):
		var arr: Array = []
		for i in POOL_SIZE:
			var p := AudioStreamPlayer.new()
			p.stream = stream
			p.bus = _sfx_bus
			add_child(p)
			arr.append(p)
		_sfx_pool[id] = arr
		_sfx_index[id] = 0
	var arr: Array = _sfx_pool[id]
	var idx: int = _sfx_index[id]
	_sfx_index[id] = (idx + 1) % POOL_SIZE
	return arr[idx]

func play_sfx(id: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	var p := _get_player(id)
	if p == null:
		return
	p.volume_db = volume_db
	p.pitch_scale = pitch_scale
	p.play()

func play_music(id: String, fade_in: float = 0.0) -> void:
	if not SFX_PATHS.has(id):
		return
	var stream := _load_stream(id)
	if stream == null:
		return
	_music_player.stream = stream
	if fade_in > 0.0:
		_music_player.volume_db = -40
		_music_player.play()
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", 0.0, fade_in)
	else:
		_music_player.volume_db = 0.0
		_music_player.play()

func stop_music(fade_out: float = 0.0) -> void:
	if fade_out > 0.0:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -40, fade_out)
		tween.tween_callback(_music_player.stop)
	else:
		_music_player.stop()

func set_bus_volume(bus_name: String, db: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, db)
