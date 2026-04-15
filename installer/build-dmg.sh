#!/bin/bash
set -euo pipefail

# ──────────────────────────────────────────────
# build-dmg.sh — Build clip-utility installer DMG
# ──────────────────────────────────────────────
# Usage: ./installer/build-dmg.sh
# Output: dist/clip-utility-1.0.0.dmg

VERSION="1.0.0"
PRODUCT="clip-utility"
IDENTIFIER="com.server-boss.clip-utility"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$ROOT_DIR/dist/build"
PKG_ROOT="$BUILD_DIR/pkg-root"
SCRIPTS_DIR="$BUILD_DIR/scripts"
DMG_DIR="$BUILD_DIR/dmg"
DIST_DIR="$ROOT_DIR/dist"

rm -rf "$BUILD_DIR"
mkdir -p "$PKG_ROOT/Resources" "$SCRIPTS_DIR" "$DMG_DIR" "$DIST_DIR"

echo "── Copying binaries..."
cp "$ROOT_DIR/bin/clip" "$PKG_ROOT/Resources/clip"
cp "$ROOT_DIR/bin/clip-tui" "$PKG_ROOT/Resources/clip-tui"
cp "$ROOT_DIR/bin/clip-menu" "$PKG_ROOT/Resources/clip-menu"

echo "── Copying install scripts..."
cp "$SCRIPT_DIR/postinstall" "$SCRIPTS_DIR/postinstall"
chmod +x "$SCRIPTS_DIR/postinstall"

echo "── Building .pkg..."
pkgbuild \
  --root "$PKG_ROOT" \
  --scripts "$SCRIPTS_DIR" \
  --identifier "$IDENTIFIER" \
  --version "$VERSION" \
  --install-location "/tmp/clip-utility-install" \
  "$BUILD_DIR/$PRODUCT.pkg"

echo "── Preparing DMG contents..."
cp "$BUILD_DIR/$PRODUCT.pkg" "$DMG_DIR/"
cp "$ROOT_DIR/README.md" "$DMG_DIR/"
cp "$ROOT_DIR/LICENSE" "$DMG_DIR/"

echo "── Creating DMG..."
hdiutil create \
  -volname "clip-utility $VERSION" \
  -srcfolder "$DMG_DIR" \
  -ov \
  -format UDZO \
  "$DIST_DIR/$PRODUCT-$VERSION.dmg"

echo "── Cleaning up..."
rm -rf "$BUILD_DIR"

echo ""
echo "✓ Built: $DIST_DIR/$PRODUCT-$VERSION.dmg"
