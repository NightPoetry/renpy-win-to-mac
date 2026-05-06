# Ren'Py Win → Mac

把只有 Windows 版的 Ren'Py 视觉小说打包成 macOS .app。

> Repackage a Windows-only Ren'Py visual novel as a macOS .app bundle.

---

## 原理

Ren'Py 游戏的 `game/` 文件夹跨平台通用。Windows 版和 Mac 版的区别只是外面套的壳不同。下载 Ren'Py SDK（自带 Mac 运行时），把 `game/` 塞进去就能跑。

---

## 快速开始

### 让 AI 帮你做（推荐）

把 `guide.md` 放到游戏所在目录，启动 [Claude Code](https://docs.anthropic.com/en/docs/claude-code)、[Trae](https://trae.ai) 或其他 AI 编程助手，直接说：

```
参考 guide.md，帮我把这个 Windows 版 Ren'Py 游戏打包成 Mac 应用
```

AI 会自动读取指南、下载 SDK、组装 .app、设置权限。过程中注意留意终端，AI 可能需要你**确认授权、输入密码或同意操作**。

### 一键脚本

修改脚本顶部三个变量，直接运行：

```bash
chmod +x build-mac.sh
./build-mac.sh
```

### 手动操作

阅读 `guide.md`，按 6 步执行。

---

## 文件说明

| 文件 | 用途 |
|-----|------|
| `guide.md` | 完整打包指南（原理 + 6步操作 + 常见问题） |
| `build-mac.sh` | 一键打包脚本，修改顶部配置即用 |

---

## 步骤概览

1. **确认 Ren'Py 版本** — SDK 版本必须 ≥ 游戏版本
2. **下载 Ren'Py SDK** — 从 renpy.org 下载，包含所有平台运行时
3. **提取 game/ 文件夹** — 从 Windows 版中复制出来
4. **组装 .app 包** — 创建目录结构、启动脚本、Info.plist
5. **解除安全限制** — `xattr -cr *.app`
6. **测试运行**

---

## 常见问题

| 问题 | 解决 |
|-----|------|
| "无法打开，无法验证开发者" | `xattr -cr *.app` |
| renpy.sh: Permission denied | `chmod +x renpy-sdk/renpy.sh` |
| 黑屏闪退 | SDK 版本不匹配，换一个 |

---

## License

MIT
