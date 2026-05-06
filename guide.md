# Ren'Py 游戏 Windows → macOS 打包指南

> 把一个只有 Windows 版的 Ren'Py 视觉小说打包成 macOS .app

---

## 原理

Ren'Py 游戏的核心是 `game/` 文件夹（.rpy 脚本 + 资源文件），跟平台无关。Windows 版和 Mac 版的区别只是外面套的壳不同：

```
Windows 版：renpy.exe + lib/py3-windows-x86_64/ + game/
Mac 版：   .app 包 + renpy.sh + lib/py3-mac-universal/ + game/
```

所以转换思路就是：**下载 Ren'Py SDK（自带 Mac 运行时），把游戏的 game/ 文件夹塞进去。**

---

## 第一步：确认游戏的 Ren'Py 版本

打开 Windows 版游戏目录，找版本信息：

```bash
# 方法1：看 renpy 目录下的版本文件
cat 游戏目录/renpy/__init__.py | grep version

# 方法2：看 log.txt（运行一次游戏后生成）
head -5 游戏目录/log.txt
```

常见版本：7.x、8.x。**SDK 版本必须匹配或高于游戏版本**，否则可能不兼容。

---

## 第二步：下载 Ren'Py SDK

去官网下载对应版本的 SDK：

```
https://www.renpy.org/latest.html
```

选择 **SDK** 下载（不是单独的某个平台版本）。SDK 包含所有平台的运行时。

下载后解压，你会得到类似 `renpy-8.x.x-sdk` 的文件夹。

---

## 第三步：提取游戏文件

从 Windows 版中提取 `game/` 文件夹。这是游戏的全部内容：

```bash
# Windows 版游戏目录结构通常是：
# 游戏名/
# ├── game/          ← 要的就是这个
# ├── lib/
# ├── renpy/
# ├── 游戏名.exe
# └── 游戏名.sh

cp -r Windows游戏目录/game /tmp/game-backup
```

---

## 第四步：组装 .app 包

### 手动构建 .app 结构

```bash
# 设置变量（按实际修改）
GAME_NAME="MyGame"
SDK_PATH="/path/to/renpy-8.x.x-sdk"
OUTPUT="${GAME_NAME}.app"

# 创建 .app 骨架
mkdir -p "${OUTPUT}/Contents/MacOS"
mkdir -p "${OUTPUT}/Contents/Resources"

# 复制 SDK 到 Resources（Mac 运行时在里面）
cp -r "${SDK_PATH}" "${OUTPUT}/Contents/Resources/renpy-sdk"

# 复制 game 文件夹到 Resources
cp -r /tmp/game-backup "${OUTPUT}/Contents/Resources/game"
```

### 创建启动脚本

```bash
cat > "${OUTPUT}/Contents/MacOS/${GAME_NAME}" << 'LAUNCHER'
#!/bin/bash
APP_DIR="$(cd "$(dirname "$0")/../Resources" && pwd)"
exec "$APP_DIR/renpy-sdk/renpy.sh" "$APP_DIR/game"
LAUNCHER

chmod +x "${OUTPUT}/Contents/MacOS/${GAME_NAME}"
```

### 创建 Info.plist

```bash
cat > "${OUTPUT}/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${GAME_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${GAME_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.game.${GAME_NAME,,}</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>${GAME_NAME}</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.13</string>
</dict>
</plist>
PLIST
```

---

## 第五步：解除 macOS 安全限制

macOS 会阻止未签名的应用运行。

```bash
# 移除隔离属性（解决"无法打开因为无法验证开发者"）
xattr -cr "${GAME_NAME}.app"

# 如果还是打不开，到系统设置 → 隐私与安全性 → 仍要打开
```

---

## 第六步：测试运行

```bash
# 直接在终端启动（能看到错误输出）
open "${GAME_NAME}.app"

# 或者用命令行直接运行启动脚本（调试用）
"${GAME_NAME}.app/Contents/MacOS/${GAME_NAME}"
```

### 常见启动问题

| 问题 | 原因 | 解决 |
|-----|------|------|
| "无法打开" | macOS 安全限制 | `xattr -cr *.app` |
| "renpy.sh: Permission denied" | SDK 脚本没有执行权限 | `chmod +x renpy-sdk/renpy.sh` |
| "python: No such file" | SDK 的 Python 没有执行权限 | `chmod -R +x renpy-sdk/lib/py3-mac-universal/` |
| 黑屏 / 闪退 | Ren'Py 版本不匹配 | 确认 SDK 版本 ≥ 游戏版本 |
| 找不到 game 目录 | 路径错误 | 检查启动脚本中的路径 |

---

## 完整一键脚本

把上面所有步骤合成一个脚本，复制即用：

```bash
#!/bin/bash
set -e

# ========== 配置区（修改这里） ==========
GAME_NAME="MyGame"                    # 游戏名称
GAME_DIR="/path/to/windows-game"      # Windows 版游戏目录
SDK_DIR="/path/to/renpy-x.x.x-sdk"   # Ren'Py SDK 目录
VERSION="1.0"                         # 版本号
# ========================================

OUTPUT="${GAME_NAME}.app"

echo "→ 创建 .app 结构..."
mkdir -p "${OUTPUT}/Contents/MacOS"
mkdir -p "${OUTPUT}/Contents/Resources"

echo "→ 复制 SDK..."
cp -r "${SDK_DIR}" "${OUTPUT}/Contents/Resources/renpy-sdk"

echo "→ 复制游戏文件..."
cp -r "${GAME_DIR}/game" "${OUTPUT}/Contents/Resources/game"

echo "→ 创建启动脚本..."
cat > "${OUTPUT}/Contents/MacOS/${GAME_NAME}" << 'LAUNCHER'
#!/bin/bash
APP_DIR="$(cd "$(dirname "$0")/../Resources" && pwd)"
exec "$APP_DIR/renpy-sdk/renpy.sh" "$APP_DIR/game"
LAUNCHER
chmod +x "${OUTPUT}/Contents/MacOS/${GAME_NAME}"

echo "→ 创建 Info.plist..."
cat > "${OUTPUT}/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${GAME_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${GAME_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.game.${GAME_NAME,,}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>${GAME_NAME}</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.13</string>
</dict>
</plist>
PLIST

echo "→ 设置权限..."
chmod -R +x "${OUTPUT}/Contents/Resources/renpy-sdk/lib/py3-mac-universal/" 2>/dev/null || true
chmod +x "${OUTPUT}/Contents/Resources/renpy-sdk/renpy.sh"
xattr -cr "${OUTPUT}"

echo "✓ 完成！双击 ${OUTPUT} 运行游戏"
```

保存为 `build-mac.sh`，修改顶部配置区，然后：

```bash
chmod +x build-mac.sh
./build-mac.sh
```

---

## .app 最终结构

```
MyGame.app/
└── Contents/
    ├── Info.plist                         ← 应用元信息
    ├── MacOS/
    │   └── MyGame                         ← 启动脚本（bash）
    └── Resources/
        ├── game/                          ← 游戏内容（从 Windows 版提取）
        │   ├── script.rpy
        │   ├── gui.rpy
        │   ├── images/
        │   ├── audio/
        │   └── ...
        └── renpy-sdk/                     ← Ren'Py SDK（提供 Mac 运行时）
            ├── renpy.sh                   ← SDK 启动入口
            ├── lib/
            │   └── py3-mac-universal/     ← Mac 平台的 Python 运行时
            ├── renpy/                     ← Ren'Py 引擎核心
            └── ...
```

---

*创建时间：2026-05-06*
*基于 DEBTORS 6.0 的实际 .app 结构逆向分析*