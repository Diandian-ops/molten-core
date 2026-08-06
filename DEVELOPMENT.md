# 开发工作流

## 日常开发循环

```bash
# 1. 拉最新
git pull

# 2. 切换/创建分支 (新功能/修 bug 走独立分支)
git switch -c feat/xxx        # 新功能
git switch -c fix/xxx-bug     # 修 bug
git switch -c refactor/xxx    # 重构

# 3. 开发 (Godot 编辑器里改代码/场景/资源)

# 4. 提交
git add <具体文件>            # 不要 git add . (见下方"提交规范")
git commit -m "type(scope): 中文一句话"

# 5. 推送并开 PR (或合并到 main)
git push -u origin feat/xxx
```

## 提交规范

格式：**`type(scope): 中文一句话描述`**

| type | 用途 | 示例 |
|---|---|---|
| `feat` | 新功能 | `feat(audio): 接入12个CC0音效` |
| `fix` | 修 bug | `fix(core): 修复敌人撞核双扣血` |
| `refactor` | 重构 (无功能变化) | `refactor(tower): 提取索敌逻辑` |
| `docs` | 文档 | `docs: 补 README 开发流程` |
| `style` | 格式/注释 | `style: 统一4空格缩进` |
| `test` | 测试 | `test(headless): 加场景自动验证` |
| `chore` | 杂项/构建 | `chore: 升级 Godot 到 4.7.1` |
| `perf` | 性能 | `perf(enemy): 缓存路径点` |
| `data` | 数值/资源 | `data(towers): 平衡水晶哨卫伤害` |
| `scene` | 场景调整 | `scene(hud): 重排顶栏布局` |

**`scope`** 写哪个子系统：`audio / core / enemy / tower / hud / level / main / select / result / boot` 等。

**提交原则**:
- ✅ 一个 commit 做一件事
- ✅ 提交前在 Godot 里跑一次无错
- ❌ 不提交 `build/`、`.godot/`、`.import/` 缓存（已被 `.gitignore` 屏蔽）
- ❌ 不混着改多个不相关的东西

## 分支策略

```
main                  # 稳定分支,只有通过测试的代码
├── feat/audio        # 新功能
├── feat/upgrade      # 新功能
├── fix/double-hit    # 修 bug
├── refactor/enemy    # 重构
└── release/v0.1      # 发布版本
```

- **`main`**: 永远保持可跑通的稳定状态
- **功能分支**: 命名前缀 `feat/` / `fix/` / `refactor/`
- **发布分支**: 命名前缀 `release/`，用 tag 标记版本

## 标签 (Tag)

```bash
# 打一个版本
git tag -a v0.1.0 -m "v0.1.0: 音效+升级双系统落地"

# 推送标签
git push origin v0.1.0
```

版本号遵循 [语义化版本](https://semver.org/)：
- **主版本号 (X.0.0)**: 重大重做
- **次版本号 (0.X.0)**: 新功能，向后兼容
- **修订号 (0.0.X)**: bug 修复

## Godot 协作特别提示

### ⚠️ 关键：每次提交前先关 Godot

```
1. Ctrl/Cmd + S 保存所有未保存的修改
2. Project → Quit 退出 Godot
3. git add / commit
4. 重开 Godot
```

**原因**：Godot 后台会写 `.godot/` 缓存，**运行时提交**可能漏掉某些 `.tres` 修改。

### 场景/资源文件冲突

Godot 的 `.tscn` 和 `.tres` 经常出现 3-way merge 冲突。**处理顺序**：

1. 不要手动改 `.tscn` 文件
2. 冲突时优先 `git checkout --ours` 或 `--theirs`（二选一）
3. 在 Godot 编辑器里**重新打开场景**，手动重新做对方的修改
4. 重新提交

### .import 文件冲突

`*.wav.import` / `*.png.import` 元数据如果冲突：

1. 删除冲突的 `.import` 文件
2. 在 Godot 中 Project → Reload Current Project
3. 让 Godot 重新生成
4. 重新提交

## 持续导出

`build/` 不进版本控制。**导出策略**：

- 本地开发：随便用 `godot --export-release` 试
- 正式版本：用 **GitHub Actions / CI** 自动构建 → 上传 Release 附件
- 临时分享给朋友：直接 `cp build/xxx.zip` 发过去

> 当前**未配置 CI**，后续可加 `.github/workflows/build.yml`。

## 存档

玩家存档 (`user://molten_core_save.json`) **不**在项目里，**不**进 git。
位置在 `~/.local/share/godot/app_userdata/molten-core/`（macOS: `~/Library/Application Support/Godot/app_userdata/molten-core/`）。

调试时可以直接删：
```bash
rm -rf ~/Library/Application\ Support/Godot/app_userdata/molten-core/
```

## 相关链接

- [GDD](GDD.md) - 游戏设计文档
- [ASSET_INTEGRATION.md](ASSET_INTEGRATION.md) - 美术资源集成
- [BUILD_SUMMARY.md](BUILD_SUMMARY.md) - 构建摘要
