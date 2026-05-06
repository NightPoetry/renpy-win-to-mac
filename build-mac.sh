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
