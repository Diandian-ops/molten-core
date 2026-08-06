# MOLTEN CORE（熔核守卫）

一款以「熔核」为核心的 2D 塔防闯关游戏。玩家扮演熔核祭司，在地图中央的熔核周围布置守卫塔，抵御从裂痕点涌来的「灼灭者」，守护熔核不被熄灭。

世界观、玩法设计与后续扩展方向见 [`docs/GDD.md`](docs/GDD.md)。

## 技术栈

- 引擎：[Godot 4.7](https://godotengine.org/)（GDScript）
- 原生支持多平台导出：**Windows / macOS / Linux / iOS / Android（APK/AAB）/ HTML5**，同一套项目、同一套代码。

## 目录结构

```
project.godot          # 项目配置（自动加载、窗口、渲染设置）
scripts/
  autoload/             # 全局单例：GameManager（进度/资源）、AudioManager、SceneRouter
  data/                 # 数值型 Resource 定义：EnemyData / TowerData / WaveEntry / WaveData / LevelData
  gameplay/             # 核心玩法逻辑：Core / Enemy / Tower / BuildSlot / SpawnManager / Level
  ui/                   # 界面逻辑：Boot / MainMenu / LevelSelect / HUD / ResultScreen
scenes/
  gameplay/              # 可复用的玩法预制体 (.tscn)
  ui/                    # HUD 场景
  boot.tscn, main_menu.tscn, level_select.tscn, level.tscn, result_screen.tscn
resources/
  towers/                # 守卫塔数值配置 (.tres)：熔火塔 / 震波塔 / 熔晶塔
  enemies/                # 敌人数值配置 (.tres)：灼奴 / 熔壳兵 / 裂痕使者
levels/                  # 关卡数据 (.tres)：level_01 ~ level_03，波次/裂痕点/星级阈值
docs/GDD.md              # 游戏设计文档（世界观、玩法、技术方案）
```

策划向的数值调整（伤害、速度、波次构成等）都在 `resources/` 和 `levels/` 下的 `.tres` 文件中，可以直接在 Godot 编辑器的 Inspector 面板里改，不需要碰代码。

## 本地运行

1. 安装 [Godot 4.7+](https://godotengine.org/download)（macOS 可用 `brew install --cask godot`）。
2. 打开 Godot，选择「导入」，指向本项目的 `project.godot`。
3. 按 F5 或点击右上角运行按钮，默认从 `scenes/boot.tscn` 启动。

也可以用命令行启动（假设已通过 Homebrew 安装并链接了 `godot` 命令）：

```bash
godot --path "." 
```

## 多平台导出

Godot 使用「导出模板」（Export Templates）为每个目标平台打包。步骤：

1. 菜单 `Editor → Manage Export Templates`，下载与当前 Godot 版本匹配的导出模板（首次导出前必须做）。
2. 菜单 `Project → Export...`，点击 `Add...` 添加对应平台的导出预设：
   - **Windows Desktop**：直接导出 `.exe`，可在 macOS 上交叉编译（需要模板，签名可选）。
   - **macOS**：导出 `.app` / `.dmg`，若要上架 App Store 或做 Gatekeeper 签名分发，需要 Apple 开发者账号做代码签名和 notarization。
   - **iOS**：导出 Xcode 项目，随后需要在 Xcode 中用 Apple 开发者账号签名并通过 TestFlight/App Store 发布，必须在 macOS 上完成这一步。
   - **Android**：配置好 Android SDK / JDK / Debug 或 Release 签名密钥后，可直接导出 `.apk`（测试用）或 `.aab`（上架 Google Play 用）。
3. 每个平台预设里可以设置图标、包名（Bundle ID / Package Name）、版本号等。
4. 点击 `Export Project` 生成对应平台的可执行文件/安装包。

详细的平台专属配置（如 Android 的 Gradle 构建、iOS 的 entitlements）请参考 [Godot 官方导出文档](https://docs.godotengine.org/en/stable/tutorials/export/index.html)，不同平台的签名证书、开发者账号需要各自单独申请。

## 已实现的框架内容（v0.3.0）

- 场景流程：启动 → 主菜单 → 关卡选择 → 关卡内玩法 → 结算面板 → 返回。
- 塔防核心循环：裂痕点按波次生成敌人 → 敌人沿熔岩路径移动向熔核 → 守卫塔自动攻击/减速 → 击杀掉落晶币 → 熔核能量归零判负 / 打完所有波次判胜。
- 数据驱动：关卡、敌人、守卫塔、Boss、波次均为 `.tres` 资源，策划可视化调整数值。
- 存档：关卡星级与解锁进度保存在 `user://molten_core_save.json`。
- 3 个示例关卡（序章 / 第一章 / 第二章），每关波次末尾接入一个 Boss。
- 打击感与特效：受击飘字、屏幕震动、粒子爆发、命中闪白、熔核受击红边与濒死心跳。
- 塔主动技能：每类塔一个主动技（消耗晶币 + CD），HUD 显示技能按钮与冷却倒计时。
- 熔核主动技能：治愈 / 全场震波 / 紧急护盾，底栏三键可点。
- 升级分支树：塔升至 Lv2 弹出分支对话框，选 A / B 不可逆（如熔火塔→爆裂/灼烧，震波塔→雷霆/震荡，熔晶塔→寒冰/穿透）。
- Boss 多阶段：3 个 Boss（熔岩巨像 / 暗影行者 / 深渊领者），随血线触发加速、召唤小怪等阶段技能。
- 音效：20 个 CC0 音效，全事件接入（开火 / 击杀 / 技能 / 胜负 / 暴击 / 心跳 / Boss 咆哮等）。
- 美术：集成 [Kenney Tower Defense Pack](https://kenney.nl/assets/tower-defense-top-down)（CC0）像素素材——塔 / 敌人 UFO / 熔核水晶 / 地面瓦片。

## v0.4.0（界面与世界观 · UI 改版）

主菜单 / UI 氛围改版，强化「熔核」主题沉浸感（延续 v0.3.0 玩法，未改动战斗逻辑）：

- **复用余烬背景组件 `EmberBackground`**：零资源依赖的动态渐变 + 余烬粒子，可挂任意 `Control` 节点，统一全 UI 视觉基调。
- **主菜单氛围重做**：动态背景 + 标题呼吸动效；按存档进度显示「继续守卫」并直达最高解锁关。
- **关卡选择卡片化**：每关一张卡片（标题 / 星级 / 锁状态 / Boss 提示），错落入场动画。
- **剧情日志系统（新增）**：左列表（按关卡解锁进度渐进解锁）+ 右详情；文案来自 `resources/story/` 下 6 篇 `StoryLog` 资源（背景 / 人物 / 序章 / 第一章 / 第二章 / 尾声），数据驱动、可在编辑器内增改。
- **结算面板风格统一**：动态余烬背景 + 面板缩放入场 + 星标弹跳；胜利时提示「通关解锁新剧情」。

> 说明：v0.4.0 的「新关卡（第 4~5 关）」尚未实装，其余 UI / 世界观内容已完成。导出构建（`build/`）仍为 v0.3.0，下次重新导出时一并更新。

## 后续方向（尚未实现）

- 移动端适配（触屏 UI + 虚拟按钮，iOS / Android 导出）。
- 背景音乐（BGM）与更丰富的音效。
- 更多关卡（第 4~5 关）。
- 自动构建 CI（GitHub Actions 导出并发布 Release）。
- 成就 / 挑战模式。

## 美术资源

- **Kenney Tower Defense (Top-Down)** - CC0 1.0 Universal 许可
  - 位置：`assets/kenney_td/tiles/`（299 个 PNG 精灵）
  - 授权：[kenney.nl](https://kenney.nl/assets/tower-defense-top-down)
  - 当前使用：
    - 守卫塔：tile181（火焰塔）
    - 敌人：tile245/246/247（不同颜色 UFO 对应灼奴/熔壳兵/裂痕使者）
    - 熔核：tile270（发光水晶）
    - 建造点：tile021（地面瓦片）

## 导出的可执行文件

项目已配置好跨平台导出预设，可在 `build/` 目录下找到：

- **macOS**: `build/macos/MoltenCore.app` (164 MB，Universal Binary，支持 Intel + Apple Silicon)
- **Windows**: `build/windows/MoltenCore.exe` (105 MB，x86_64)

两个平台均已使用 Godot 4.7.1 导出模板构建，可直接运行。最近一次重新导出为 2026-08-06（v0.4.0，含 UI 改版：主菜单 / 关卡选择 / 剧情日志 / 结算面板氛围重做）。
