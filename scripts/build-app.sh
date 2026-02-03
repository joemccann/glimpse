#!/bin/bash
#
# build-app.sh - Build Glimpse as a macOS .app bundle
#
# Usage:
#   ./scripts/build-app.sh              # Build to ./build/
#   ./scripts/build-app.sh --install    # Build and copy to /Applications
#

set -e

# Configuration
APP_NAME="Glimpse"
BUNDLE_NAME="Glimpse"
BUNDLE_ID="com.glimpse.app"
VERSION="1.5.0"

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SWIFT_PACKAGE="$PROJECT_ROOT/Glimpse"
BUILD_DIR="$PROJECT_ROOT/build"
APP_BUNDLE="$BUILD_DIR/$BUNDLE_NAME.app"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse arguments
INSTALL=false
for arg in "$@"; do
    case $arg in
        --install)
            INSTALL=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--install]"
            echo ""
            echo "Options:"
            echo "  --install    Copy the app to /Applications after building"
            echo "  --help       Show this help message"
            exit 0
            ;;
    esac
done

echo ""
echo "=========================================="
echo "  Building $APP_NAME"
echo "=========================================="
echo ""

# Step 1: Build release binary
log_info "Building release binary..."
cd "$SWIFT_PACKAGE"
swift build -c release 2>&1 | while read line; do
    echo "  $line"
done

BINARY_PATH="$SWIFT_PACKAGE/.build/release/$BUNDLE_NAME"
if [ ! -f "$BINARY_PATH" ]; then
    log_error "Build failed - binary not found at $BINARY_PATH"
    exit 1
fi
log_success "Binary built successfully"

# Step 2: Run tests
log_info "Running tests..."
swift test 2>&1 | tail -5 | while read line; do
    echo "  $line"
done
log_success "All tests passed"

# Step 3: Create app bundle structure
log_info "Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Step 4: Copy binary
log_info "Copying binary..."
cp "$BINARY_PATH" "$APP_BUNDLE/Contents/MacOS/$BUNDLE_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$BUNDLE_NAME"

# Step 4b: Copy menu bar icon
log_info "Copying menu bar icon..."
MENUBAR_ICON_DIR="$SWIFT_PACKAGE/Glimpse/Resources/Assets.xcassets/MenuBarIcon.imageset"
if [ -f "$MENUBAR_ICON_DIR/menubar@2x.png" ]; then
    cp "$MENUBAR_ICON_DIR/menubar@2x.png" "$APP_BUNDLE/Contents/Resources/menubar.png"
    log_success "Menu bar icon copied"
else
    log_warning "Menu bar icon not found - using fallback"
fi

# Step 5: Create Info.plist
log_info "Creating Info.plist..."
cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>${BUNDLE_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticTermination</key>
    <true/>
    <key>NSSupportsSuddenTermination</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2025. MIT License.</string>
</dict>
</plist>
EOF

# Step 6: Create PkgInfo
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# Step 7: Create app icon from pre-generated assets
log_info "Creating app icon..."
ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"
ASSETS_ICONSET="$SWIFT_PACKAGE/Glimpse/Resources/Assets.xcassets/AppIcon.appiconset"

# Create iconset directory and copy pre-generated icons
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

if [ -d "$ASSETS_ICONSET" ] && [ -f "$ASSETS_ICONSET/icon_512x512@2x.png" ]; then
    cp "$ASSETS_ICONSET"/icon_*.png "$ICONSET_DIR/"

    # Convert iconset to icns
    iconutil -c icns "$ICONSET_DIR" -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns" 2>/dev/null && {
        log_success "App icon created from pre-generated assets"
    } || {
        log_warning "Could not create .icns file - app will use default icon"
    }
    rm -rf "$ICONSET_DIR"
else
    log_warning "Pre-generated icons not found at $ASSETS_ICONSET"
    log_warning "Run the icon generation script or add icons manually"
fi

# Step 8: Code sign (ad-hoc if no identity specified)
log_info "Code signing (ad-hoc)..."
codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null || {
    log_warning "Code signing failed - app may not run on other machines"
}
log_success "App signed"

# Step 9: Verify the bundle
log_info "Verifying app bundle..."
if [ -f "$APP_BUNDLE/Contents/MacOS/$BUNDLE_NAME" ] && \
   [ -f "$APP_BUNDLE/Contents/Info.plist" ]; then
    log_success "App bundle verified"
else
    log_error "App bundle verification failed"
    exit 1
fi

# Step 10: Install if requested
if [ "$INSTALL" = true ]; then
    log_info "Installing to /Applications..."

    # Check if app is running
    if pgrep -x "$BUNDLE_NAME" > /dev/null; then
        log_warning "App is currently running. Stopping it..."
        pkill -x "$BUNDLE_NAME" || true
        sleep 1
    fi

    # Remove old version if exists
    if [ -d "/Applications/$BUNDLE_NAME.app" ]; then
        rm -rf "/Applications/$BUNDLE_NAME.app"
    fi

    # Copy new version
    cp -R "$APP_BUNDLE" "/Applications/"
    log_success "Installed to /Applications/$BUNDLE_NAME.app"
fi

# Summary
echo ""
echo "=========================================="
echo "  Build Complete!"
echo "=========================================="
echo ""
echo "  App bundle: $APP_BUNDLE"
echo "  Version:    $VERSION"
echo ""

if [ "$INSTALL" = true ]; then
    echo "  Installed to /Applications"
    echo ""
    echo "  To launch: open /Applications/$BUNDLE_NAME.app"
else
    echo "  To install: $0 --install"
    echo "  To launch:  open $APP_BUNDLE"
fi

echo ""
