extends Node
## 单一主题来源（autoload：全局名 ThemeConstants）：所有 UI chrome 的调色板与字号阶梯引用此处。
## 设计 rationale：审计发现 gold/danger/locked/dim 四套色与散落 font_size 在 6 个脚本重复硬编码，
## 改一处漏九处。集中后任何视觉微调只需改本文件。emoji 仍作为内容语义图标保留（无替换资产）。
## 用 autoload 而非 class_name：headless 解析环境下 class_name 全局名解析不可靠，autoload 全局名恒可用。

# ── 调色板（单一来源）──
const GOLD        := Color(1.0, 0.80, 0.30, 1.0)  # 胜利 / 强调 / 星级
const DANGER      := Color(0.90, 0.35, 0.30, 1.0) # 失败 / 濒死红边
const LOCKED      := Color(0.50, 0.50, 0.60, 1.0) # 锁定卡基色（alpha 由调用方另设）
const LOCKED_TEXT := Color(0.60, 0.60, 0.65, 1.0) # 「（未解锁）」文字
const TEXT_DIM    := Color(0.80, 0.80, 0.85, 1.0) # 次要文字 / 提示
const TEXT_DIM_A  := Color(0.80, 0.80, 0.85, 0.80) # 提示半透明版
const BTN_DISABLED := Color(0.40, 0.40, 0.40, 0.50) # 不可建造塔灰化
const HOVER       := Color(1.0, 0.85, 0.45, 1.0)  # 卡片 hover / 键盘聚焦边框高亮

# ── 字号阶梯（TypeScale）──
const TITLE := 30  # 结算大标题 / 设置标题
const H2    := 22  # 关卡卡关名 / 列表标题
const STAR  := 20  # 星级
const BODY  := 18  # 正文
const SMALL := 14  # 次要提示

# ── 重用样式盒：统一卡片 hover / 聚焦视觉反馈 ──
## 普通态：深底 + 极淡边框，降低默认存在感，hover 时才「亮」出来。
func card_normal_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.10, 0.14, 0.85)
	sb.border_color = Color(0.30, 0.28, 0.34, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(12)
	return sb

## 高亮态：金色边框 + 略亮底，制造可点性反馈（鼠标 hover 或键盘聚焦）。
func card_hover_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.20, 0.16, 0.18, 0.95)
	sb.border_color = HOVER
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(12)
	return sb

# ── 列表按钮样式（剧情日志等）──
func button_normal_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.14, 0.12, 0.16, 0.90)
	sb.border_color = Color(0.30, 0.28, 0.34, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(10)
	return sb

func button_hover_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.22, 0.18, 0.20, 0.95)
	sb.border_color = HOVER
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(10)
	return sb

func button_disabled_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.10, 0.12, 0.60)
	sb.border_color = Color(0.25, 0.24, 0.28, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(10)
	return sb
