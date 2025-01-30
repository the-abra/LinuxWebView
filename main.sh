#!/bin/bash

# Load logging utilities
source lib.sh.d/log.lib

# PHT Detection Warning
if [[ -f ./module.pht ]]; then
    log.warn "PHT Detected! The build process may successful but run is not guaranteed"
fi

# Ensure GCC is installed
if ! command -v gcc &>/dev/null; then
    log.info "Setting up dependencies..."
    
    # Update package list and install required dependencies
    if ! pacman -Sy --noconfirm gcc webkit2gtk gtk3 flatpak flatpak-builder git base-devel cmake wget; then
        log.error "Failed to install dependencies. Exiting..."
        exit 1
    fi

    # Download and set up AppImageTool
    APPIMAGE_TOOL="/usr/local/bin/appimagetool"
    if [[ ! -f "$APPIMAGE_TOOL" ]]; then
        log.info "Downloading AppImageTool..."
        wget -q https://github.com/AppImage/AppImageKit/releases/latest/download/appimagetool-x86_64.AppImage -O "$APPIMAGE_TOOL" || {
            log.error "Failed to download AppImageTool. Exiting..."
            exit 1
        }
        chmod +x "$APPIMAGE_TOOL"
        mkdir -p webview-app.AppDir/usr/bin
        mkdir -p webview-app.AppDir/usr/share/applications
        mkdir -p webview-app.AppDir/usr/share/icons
        cp src/webview.desktop webview-app.AppDir/usr/share/applications/webview.desktop
        cp src/webview.png webview-app.AppDir/usr/share/icons/webview.png
        log.info "AppImageTool installed successfully."
    fi
fi

# Compile the application
log.info "Compiling the application..."
gcc main.c -o build/webview-app \
    $(pkg-config --cflags --libs webkit2gtk-4.0 gtk+-3.0) \
    -static-libgcc -static-libstdc++ || {
        log.error "Compilation failed."
        exit 1
    }

log.success "GCC build completed successfully. Moving -> webview-app.AppDir/usr/bin/"
mv webview-app webview-app.AppDir/usr/bin/

# Generate the AppImage
cd webview-app.AppDir
appimagetool --no-appstream .

./webview-app-x86_64.AppImage || log.error "Run Faild, try on host machine."