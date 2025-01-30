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

    if ! ( apt update && apt install -y gcc g++ make cmake file libwebkit2gtk-4.0-dev libgtk-3-dev build-essential libfuse2 wget gstreamer1.0-libav gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly ); then
        log.error "Failed to install dependencies. Exiting..."
        log.sub "try to install manualy."
        [[ -f ./module.pht ]] && log.sub "Access to shell : pht run LinuxWebView -c bash"
        exit 1
    else
        pacman -Sy --noconfirm gcc file webkit2gtk gtk3 base-devel fuse2 cmake wget || {
        log.error "Failed to install dependencies. Exiting..."
        log.sub "try to install manualy."
        [[ -f ./module.pht ]] && log.sub "Access to shell : pht run LinuxWebView -c bash"
        exit 1
        }
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
        log.info "AppImageTool installed successfully."
    fi
fi

# Compile the application
log.info "Compiling the application..."

gcc main.c -o webview-app.AppDir/usr/bin/webview-app \
    $(pkg-config --cflags --libs  webkit2gtk-4.0 gtk+-3.0) \
    -static-libgcc -static-libstdc++ &> /home/gccbuild.log || {
        log.error "Compilation failed."
        log.sub "LOG: /home/gccbuild.log"
        exit 1
    }

log.done "GCC build completed successfully."
log.sub "SAVED -> webview-app.AppDir/usr/bin/webview-app"

# Generate the AppImage and try to run
! [[ -d build ]] && mkdir build
rm build/* &> /dev/null
appimagetool webview-app.AppDir build/webview.AppImage &> /home/appimagebuild.log || {
    log.error "AppImage Build Failed"
    log.sub "LOG: /home/appimagebuild.log"
    exit 1
}
log.done "AppImage build completed successfully."
log.sub "SAVED -> build/webview.AppImage"


if ! [[ $1 =~ (workflow|CI|CD) ]]; then
    log.info "Trying to run."
    ./build/webview.AppImage https://www.google.com &> /home/appimagerun.log || { 
        log.error "Run Faild, try on host machine." 
        log.sub "LOG: /home/appimagerun.log"
        exit 1 
    }
fi