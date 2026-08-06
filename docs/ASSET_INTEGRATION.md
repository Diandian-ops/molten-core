# Kenney 素材集成说明

## 集成时间
2026-08-05

## 素材来源
**Kenney Tower Defense (Top-Down) Pack**
- 授权：CC0 1.0 Universal (Public Domain)
- 来源：https://kenney.nl/assets/tower-defense-top-down
- 包含：299 个 64x64px PNG 精灵图
- 内容：塔、敌人（UFO）、地面瓦片、装饰、UI 元素

## 素材映射表

### 守卫塔 (Towers)
| 游戏内名称 | 使用的贴图文件 | Kenney 编号 | 说明 |
|-----------|--------------|------------|------|
| 熔火塔 | tower_flame_icon.png | tile181 | 红色导弹发射塔 |
| 震波塔 | tower_shock_icon.png | tile249 | 紫色激光炮塔 |
| 熔晶塔 | tower_crystal_icon.png | tile241 | 蓝色炮塔 |

### 敌人 (Enemies)
| 游戏内名称 | 使用的贴图文件 | Kenney 编号 | 说明 |
|-----------|--------------|------------|------|
| 灼奴 | enemy_slave.png | tile245 | 黄色 UFO（基础单位）|
| 熔壳兵 | enemy_shellguard.png | tile246 | 蓝色 UFO（坦克单位）|
| 裂痕使者 | enemy_rift_herald.png | tile247 | 红色 UFO（快速单位）|

### 核心元素 (Core)
| 游戏内名称 | 使用的贴图文件 | Kenney 编号 | 说明 |
|-----------|--------------|------------|------|
| 熔核 | towerDefense_tile270.png | tile270 | 橙色发光水晶 |

### 建造点 (Build Slots)
| 游戏内名称 | 使用的贴图文件 | Kenney 编号 | 说明 |
|-----------|--------------|------------|------|
| 建造位 | towerDefense_tile021.png | tile021 | 浅色地面瓦片 |

## 场景文件修改

### 替换的场景
1. `scenes/gameplay/tower.tscn` - 从 Polygon2D 改为 Sprite2D
2. `scenes/gameplay/enemy.tscn` - 通用模板
3. `scenes/gameplay/enemy_slave.tscn` - 新建（使用 tile245）
4. `scenes/gameplay/enemy_shellguard.tscn` - 新建（使用 tile246）
5. `scenes/gameplay/enemy_rift_herald.tscn` - 新建（使用 tile247）
6. `scenes/gameplay/core.tscn` - 从 Polygon2D 改为 Sprite2D
7. `scenes/gameplay/build_slot.tscn` - 添加地面贴图背景

### 资源文件更新
- `resources/towers/tower_flame.tres` - 添加 icon 引用
- `resources/towers/tower_shock.tres` - 添加 icon 引用
- `resources/towers/tower_crystal.tres` - 添加 icon 引用
- `resources/enemies/enemy_slave.tres` - 场景引用改为 enemy_slave.tscn
- `resources/enemies/enemy_shellguard.tres` - 场景引用改为 enemy_shellguard.tscn
- `resources/enemies/enemy_rift_herald.tres` - 场景引用改为 enemy_rift_herald.tscn

## 素材库位置
所有 299 个 Kenney 瓦片都已复制到：
```
assets/kenney_td/tiles/towerDefense_tile001.png ~ towerDefense_tile299.png
assets/kenney_td/License.txt (CC0 许可证副本)
```

## 可用但尚未使用的素材

### 塔基础和变体 (tile161-200)
- 多种颜色的炮塔基座（灰/棕/蓝/绿）
- 不同武器类型的炮管
- 可用于塔的升级视觉变化

### 地形瓦片 (tile001-080)
- 泥土、草地、沙地、雪地
- 道路、围栏、装饰物
- 可用于构建关卡地图背景

### UI 和装饰 (tile081-160, tile201-240)
- 血条、能量条
- 按钮、面板
- 爆炸效果、弹药图标

### 其他敌人变体 (tile248-260)
- 更多 UFO 颜色（绿/紫/灰）
- 可用于后续新敌人类型

## 技术细节

### 缩放
- 敌人：scale = Vector2(0.5, 0.5)（原图 64x64 缩小到 32x32 显示）
- 塔：scale = Vector2(1.0, 1.0) + offset = Vector2(0, -8)（向上偏移 8 像素）
- 熔核：scale = Vector2(1.2, 1.2)（放大 20%）

### 导入设置
Godot 已自动为所有 PNG 生成 .import 文件，默认使用 2D 纹理过滤（线性插值），适合像素艺术。

## 后续优化建议

1. **为不同等级的塔添加视觉差异**：可使用 tile161-200 中不同颜色/样式的塔
2. **添加地图背景**：使用 tile001-080 中的地形瓦片拼接地图
3. **粒子效果**：使用 tile081-120 中的爆炸/火花图标创建攻击特效
4. **UI 美化**：使用 tile201-240 中的按钮/面板素材替换当前的 ColorRect

## 测试结果

✅ macOS 导出成功 (164 MB, Universal Binary)
✅ Windows 导出成功 (105 MB, x86_64)
✅ 游戏可正常启动并显示新素材
✅ 所有 299 个素材已导入 Godot 资源系统
