extends Resource
## 剧情日志条目：数据驱动，按 unlock_level_id 渐进解锁。
class_name StoryLog

@export var id: String = ""
@export var title: String = ""           # 条目标题
@export var chapter: String = ""         # 章节标签，如 "序章" / "背景"
@export var body: String = ""            # 正文（支持 \n 换行）
@export var unlock_level_id: String = "" # 关联的关卡 id；空字符串 = 始终可见
