# MOLTEN CORE v0.3.0 升级路线图

**目标**: 从"能玩 MVP"到"好玩的核心循环"
**工作量**: 1 周
**核心改动**: 打击感 + 技能系统 + 升级分支树 + Boss 系统

---

## 1. 打击感大改造 (P1)

### 1.1 塔开火反馈
| 元素 | 实现 |
|---|---|
| 后坐力 | 炮口瞬间后退 4px，0.08s 弹回 (AnimationPlayer / Tween) |
| 枪口烟 | 一个 Sprite2D (8 帧烟雾 PNG), 0.3s 后销毁 |
| 火光闪烁 | 开火瞬间 `modulate.a = 1.0`, 0.1s 渐变到 0.6 |

### 1.2 弹道
| 元素 | 实现 |
|---|---|
| 拖尾 | Line2D 实时绘制上一帧位置 (3 段) |
| 命中爆裂 | 4 帧 particle (CPUParticles2D), 0.3s |
| 暴击时 | 额外 2 个碎屑 + 屏幕 0.05s 轻微抖 |

### 1.3 敌人受击
| 元素 | 实现 |
|---|---|
| 变白 | `_on_damage` 时 `modulate = WHITE`, 0.06s 渐变回原色 |
| 血条飘字 | `+8` (金币) 飘字, 上飘 30px, 0.5s 后销毁 |
| 暴击 | 红色大字, 上飘 50px |
| 死亡 | 6 颗碎片粒子飞溅, 0.5s |

### 1.4 熔核反馈
| 元素 | 实现 |
|---|---|
| 受伤 | 全屏红边 pulse (ColorRect 在 HUD), 0.3s 渐隐 |
| 濒死 (<20%) | 持续低频心跳 (新增 `heartbeat.wav`) + 红边每 1s 闪 |
| 摧毁 | 黑屏 + 熔核粒子爆发 200 颗, 1.5s |
| 受击闪烁 | Sprite 0.05s 变白 |

### 1.5 数字飘字 (新系统)
新增 `scripts/effects/floating_text.gd`:
- 接收 `position + text + color + distance`
- Tween 上飘 + 渐隐
- 父节点: `Level/Effects/FloatingTexts`

### 1.6 屏幕震动 (新系统)
新增 `scripts/effects/screen_shake.gd`:
- `Camera2D.add_trauma(amount)` → `_process` 计算 offset
- `trauma` 衰减率: 0.05/帧
- 全局访问: `Camera2D.trauma += 0.3`

---

## 2. 技能系统 (P1)

### 2.1 塔技能 (主动,消耗晶币 50,CD 15s)
| 塔 | 技能 | 效果 |
|---|---|---|
| 水晶 | 冰霜新星 | 范围内所有敌人减速 50%, 持续 2s |
| 烈焰 | 烈焰风暴 | 锥形区域 90°, 立即伤 50, 3 段灼烧 |
| 震颤 | 雷霆震击 | 全场所有敌人受 80 伤 + 眩晕 0.5s |

### 2.2 熔核技能 (主动,CD 30s)
| 技能 | 消耗 | 效果 |
|---|---|---|
| 紧急治愈 | 30 晶币 | 熔核回 2 滴血 |
| 全场震波 | 50 晶币 | 全体敌人伤 30 + 减速 30% 持续 2s |
| 紧急护盾 | 80 晶币 | 8s 内熔核免伤 |

### 2.3 数据结构
在 `TowerData` 新增:
```gdscript
@export var skill_name: String = ""
@export var skill_duration: float = 0.0
@export var skill_radius: float = 0.0
@export var skill_damage: int = 0
@export var skill_slow: float = 0.0
@export var skill_stun: float = 0.0
@export var skill_cost: int = 50
@export var skill_cooldown: float = 15.0
@export var skill_cone_angle: float = 0.0   # 0=圆形, >0=扇形
```

在 `tower.gd` 新增:
- `skill_ready: bool`
- `_skill_cooldown_timer: float`
- `use_skill() -> bool` (返回是否成功)
- `signal skill_used`

### 2.4 UI
- HUD 选塔时显示技能按钮 (带 CD 倒计时圈)
- 熔核技能: 3 个按钮在 HUD 底栏, 灰色时禁用

---

## 3. 升级分支树 (P2)

### 3.1 概念
不再"线性 +1 +1"。Lv2 时玩家**选一个分支**, 不可逆。

### 3.2 树形结构

```
Crystal Tower Lv1 (基础)
  ├─ Lv2-A: 寒冰之心
  │     ├─ Lv3-A1: 冰封之触 (减速 +80%)
  │     └─ Lv3-A2: 极寒之息 (减速 +50% + 持续伤)
  └─ Lv2-B: 穿透水晶
        ├─ Lv3-B1: 碎裂弹 (穿透 +5)
        └─ Lv3-B2: 棱镜折射 (穿透 +3 + 分裂 2)

Flame Tower Lv1
  ├─ Lv2-A: 灼烧之心
  │     ├─ Lv3-A1: 持续燃烧 (DoT 翻倍)
  │     └─ Lv3-A2: 烈焰光环 (近身灼烧)
  └─ Lv2-B: 爆裂之心
        ├─ Lv3-B1: 死亡爆炸 (半径翻倍)
        └─ Lv3-B2: 燃烧弹 (弹道留火)

Shock Tower Lv1
  ├─ Lv2-A: 雷霆之心
  │     ├─ Lv3-A1: 雷链 (弹射 +3)
  │     └─ Lv3-A2: 雷云 (召唤持续 5s 雷区)
  └─ Lv2-B: 震荡之心
        ├─ Lv3-B1: 减速力场 (近战 30% 减速)
        └─ Lv3-B2: 强震 (击中后退)
```

### 3.3 数据结构
新增 `scripts/data/tower_upgrade_branch.gd`:
```gdscript
class_name TowerUpgradeBranch extends Resource

@export var name: String
@export var icon: Texture2D
@export var upgrades: Array[TowerData]   # 后续等级
@export var description: String
```

`TowerData` 新增:
```gdscript
@export var branch_a: TowerUpgradeBranch
@export var branch_b: TowerUpgradeBranch
@export var skill_data: TowerData        # 技能版(独立数据)
```

### 3.4 UI
- Lv2 升级时弹出**双塔对比**对话框 (左/右 视觉化对比)
- 玩家点击左侧/右侧选择
- 不可逆, 不能中途改

---

## 4. Boss 系统 (P2)

### 4.1 3 个 Boss (每个关卡末)

| 关卡 | Boss | 特点 |
|---|---|---|
| 1 | 熔岩巨像 | 高血量 (500), 慢速 (20), 每 5s 释放一次小怪潮 |
| 2 | 暗影行者 | 中血量 (350), 快 (50), 每隔 3s 进入隐身 1s, 现身时放扇形伤 |
| 3 | 深渊领者 | 巨血量 (1200), 中速 (30), 每 10s 全屏震波, 半血后狂暴 (2x speed) |

### 4.2 实现
- `EnemyData` 新增 `is_boss: bool` 和 `boss_phases: Array[BossPhase]`
- `BossPhase` Resource: `hp_threshold + speed_mult + spawn_interval + skill_damage`
- 视觉: Boss 尺寸 1.5x, 红色边框, 顶部血条常驻
- **入场**时镜头拉近, 0.5s, 配 epic 短音

---

## 5. 实施任务拆分

### 任务 1: 基础效果系统 (P1 基础)
- [ ] `scripts/effects/floating_text.gd` (飘字)
- [ ] `scripts/effects/screen_shake.gd` (震屏, 挂 main camera)
- [ ] `scripts/effects/particle_burst.gd` (粒子爆发通用, 接受 color/duration/count)
- [ ] `assets/audio/sfx/heartbeat.wav` + `critical_hit.wav` + `boss_roar.wav` (3 新音效)
- [ ] 在 level.tscn 加 `Effects` 节点

### 任务 2: 塔开火反馈 (P1)
- [ ] tower.gd 集成后坐力 (Tween position)
- [ ] tower.gd 集成火光闪烁
- [ ] projectile.gd 集成拖尾 Line2D
- [ ] projectile.gd 命中爆裂粒子
- [ ] enemy.gd 变白闪 + 飘字

### 任务 3: 熔核反馈 (P1)
- [ ] core.gd 受伤红边 (新增 hud 红边 ColorRect, 监听 core_damaged)
- [ ] core.gd 濒死心跳 (新增 _heartbeat_node 节点, <20% 持续震)
- [ ] core.gd 摧毁黑屏 + 粒子爆发
- [ ] core.gd 受击闪烁 (modulate)

### 任务 4: 塔技能 (P1)
- [ ] tower_data.gd 加 skill_* 字段
- [ ] tower.gd 加 use_skill() / _skill_cooldown
- [ ] hud.gd 选塔时显示技能按钮
- [ ] hud.gd 按下技能 → 调 tower.use_skill()
- [ ] 三种塔 .tres 加技能配置

### 任务 5: 熔核技能 (P1)
- [ ] core.gd 加 use_skill(skill_id) (3 个技能: 治愈/震波/护盾)
- [ ] core.gd 加 _shield_timer / _slow_aura_timer
- [ ] hud.gd 加 3 个熔核技能按钮
- [ ] hud.gd 监听 _on_core_skill_pressed

### 任务 6: 升级分支树 (P2)
- [ ] tower_upgrade_branch.gd 新 Resource
- [ ] tower_data.gd 加 branch_a / branch_b
- [ ] 6 条分支对应的 6 份 TowerData 资源 (每塔 2 终极,共 6 终极)
- [ ] tower.gd 加 `current_branch` 字段
- [ ] hud 升级时检测 level==2 → 弹分支选择
- [ ] 新建 `scripts/ui/branch_select_dialog.gd` + scene

### 任务 7: Boss 系统 (P2)
- [ ] boss_phase.gd 新 Resource
- [ ] enemy_data.gd 加 is_boss / boss_phases
- [ ] enemy.gd 加 _update_boss_phases()
- [ ] boss_entry 视觉: 1.5x scale + 红边框 + 顶部血条
- [ ] 3 份 .tres: boss_lava_golem, boss_shadow_walker, boss_abyss_lord
- [ ] level_01/02/03 末尾加 boss 刷出
- [ ] boss 入场镜头拉近

### 任务 8: 集成测试 (P1+P2)
- [ ] 跑全场景 instantiate
- [ ] 跑音频加载
- [ ] 跑 headless 战斗循环 60s
- [ ] 跑双平台导出

---

## 6. 验收标准

### 玩法
- ✅ 选塔→建→开火, 看到后坐力/火光/烟/弹道拖尾
- ✅ 敌人死亡飘 "+8" 数字
- ✅ 塔 Lv2 弹分支对话框
- ✅ 塔/熔核技能按钮亮起, 点按产生效果 + CD
- ✅ 最后一波 Boss 出现, 入场镜头拉近
- ✅ 熔核濒死心跳, 摧毁黑屏粒子

### 性能
- ✅ 60 FPS 满屏 30 敌人 + 5 塔 + 50 弹道
- ✅ 飘字/粒子/震屏不卡

### 代码
- ✅ 数据驱动 (新增分支/技能不需改 .gd)
- ✅ 单一职责 (effect 系统独立)

---

## 7. 时间表

| 任务 | 估计 |
|---|---|
| 1 基础效果系统 | 0.5 天 |
| 2 塔开火反馈 | 0.5 天 |
| 3 熔核反馈 | 0.5 天 |
| 4 塔技能 | 0.5 天 |
| 5 熔核技能 | 0.5 天 |
| 6 升级分支 | 1 天 |
| 7 Boss | 1 天 |
| 8 集成 | 0.5 天 |
| **总计** | **~5 天 (含集成)** |

---

## 8. 不在 v0.3.0 范围 (后续)

- 新关卡 (第 4-5 关) → v0.4.0
- 主菜单改版 → v0.4.0
- 剧情日志 → v0.4.0
- 成就/挑战模式 → v0.5.0
- 配乐 → v0.5.0
