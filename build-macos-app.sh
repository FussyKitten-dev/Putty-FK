#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
APP="$SCRIPT_DIR/PuTTY.app"

# Check for required tools
for cmd in cmake make python3 iconutil magick; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: '$cmd' not found. Install with: brew install cmake imagemagick"
        exit 1
    fi
done

if ! pkg-config --exists gtk+-3.0 2>/dev/null; then
    echo "Error: GTK3 not found. Install with: brew install gtk+3"
    exit 1
fi

echo "==> Configuring..."
cmake -B "$BUILD_DIR" -S "$SCRIPT_DIR" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="$(brew --prefix)" 2>/dev/null

echo "==> Building..."
cmake --build "$BUILD_DIR" --parallel

echo "==> Building icons..."
cd "$SCRIPT_DIR/icons"
for size in 16 32 48 64 128 256 512; do
    python3 mkicon.py putty_icon $size putty-${size}.pam
    magick putty-${size}.pam putty-${size}.png
    if [ $size -le 64 ]; then
        python3 mkicon.py -2 putty_icon $size putty-${size}-mono.pam
        magick putty-${size}-mono.pam putty-${size}-mono.png
    fi
done

ICONSET="$SCRIPT_DIR/icons/PuTTY.iconset"
mkdir -p "$ICONSET"
magick putty-16.png   "$ICONSET/icon_16x16.png"
magick putty-32.png   "$ICONSET/icon_16x16@2x.png"
magick putty-32.png   "$ICONSET/icon_32x32.png"
magick putty-64.png   "$ICONSET/icon_32x32@2x.png"
magick putty-128.png  "$ICONSET/icon_128x128.png"
magick putty-256.png  "$ICONSET/icon_128x128@2x.png"
magick putty-256.png  "$ICONSET/icon_256x256.png"
magick putty-512.png  "$ICONSET/icon_256x256@2x.png"
magick putty-512.png  "$ICONSET/icon_512x512.png"
iconutil -c icns "$ICONSET" -o "$SCRIPT_DIR/icons/PuTTY.icns"
cd "$SCRIPT_DIR"

echo "==> Assembling PuTTY.app..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BUILD_DIR/puttyapp" "$APP/Contents/MacOS/PuTTY"
cp "$SCRIPT_DIR/icons/PuTTY.icns" "$APP/Contents/Resources/PuTTY.icns"

cat > "$APP/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIconFile</key>
    <string>PuTTY</string>
    <key>CFBundleName</key>
    <string>PuTTY</string>
    <key>CFBundleDisplayName</key>
    <string>PuTTY</string>
    <key>CFBundleExecutable</key>
    <string>PuTTY</string>
    <key>CFBundleIdentifier</key>
    <string>org.tartarus.projects.putty.macputty</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo ""
echo "Done! PuTTY.app is ready at: $APP"
echo "To open a second window: open -n PuTTY.app"
