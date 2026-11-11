#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

APP_NAME=Tomatea
BUILD_DIR=.build/app
APP="$BUILD_DIR/$APP_NAME.app"
DEST="/Applications/$APP_NAME.app"

swift build -c release

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp ".build/release/$APP_NAME" "$APP/Contents/MacOS/"
cp Assets/AppIcon.icns "$APP/Contents/Resources/"
cp -R ".build/release/${APP_NAME}_${APP_NAME}.bundle" "$APP/Contents/Resources/"
cp -R ".build/release/${APP_NAME}_${APP_NAME}Core.bundle" "$APP/Contents/Resources/"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>$APP_NAME</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleIdentifier</key><string>com.asier.tomatea</string>
  <key>CFBundleName</key><string>$APP_NAME</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

codesign --force --deep -s - "$APP"

quit_app_like_cmd_q() {
  osascript \
    -e "if application \"$1\" is running then" \
    -e "  tell application \"$1\" to quit" \
    -e "end if"
}

force_kill_if_running() {
  if pgrep -x "$1" >/dev/null; then
    pkill -x "$1"
  fi
}

wait_until_stopped() {
  while pgrep -x "$1" >/dev/null; do sleep 0.2; done
}

quit_app_like_cmd_q "$APP_NAME" || force_kill_if_running "$APP_NAME"
wait_until_stopped "$APP_NAME"
rm -rf "$DEST"
cp -R "$APP" "$DEST"
open "$DEST"

echo "Installed $DEST"
