#!/bin/bash
set -e

APP_NAME="Signal"
APP_DIR="$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "🧹 Eski derleme temizleniyor..."
rm -rf "$APP_DIR"

echo "📁 Dizin yapısı oluşturuluyor..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

echo "📝 Info.plist kopyalanıyor..."
cp Info.plist "$CONTENTS_DIR/"

echo "🖼️ İkon kopyalanıyor..."
cp Resources/AppIcon.icns "$RESOURCES_DIR/" 2>/dev/null || true

echo "🛠️ Swift kodları derleniyor..."
# Find all swift source files
SOURCES=$(find Source -name "*.swift")

swiftc -g -Onone \
  -target arm64-apple-macosx12.0 \
  -Xlinker -rpath -Xlinker @executable_path/../Frameworks \
  $SOURCES -o "$MACOS_DIR/$APP_NAME"

echo "🔐 Uygulama Kod İmzası (Code Sign) oluşturuluyor..."
codesign -s "-" --force --deep "$APP_DIR"

echo "✅ Derleme başarılı! Uygulama '$APP_DIR' olarak hazırlandı."
echo "Çalıştırmak için: open $APP_DIR"
