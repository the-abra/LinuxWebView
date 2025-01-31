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

    if  apt update &> /dev/null && apt install -y gcc g++ make cmake file libwebkit2gtk-4.0-dev libgtk-3-dev libglib2.0-bin build-essential libfuse2 wget gstreamer1.0-libav gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly ; then
        log.error "Failed to install dependencies. Exiting..."
        log.sub "try to install manualy."
        [[ -f ./module.pht ]] && log.sub "Access to shell : pht run LinuxWebView -c bash"
        exit 1
    else
        pacman -Sy --noconfirm gcc file webkit2gtk gtk3 glib2 base-devel fuse2 cmake wget || {
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

# Compile the vebviewer
log.info "Compiling the application..."


# webviewer.c
gcc webviewer.c -o webview-app.AppDir/usr/bin/webviewer \
    $(pkg-config --cflags --libs  webkit2gtk-4.0 gtk+-3.0) \
    -static-libgcc -static-libstdc++ &> /home/webviewer.log || {
        log.error "Compilation failed."
        log.sub "LOG: /home/webviewer.log"
        [[ $1 =~ (workflow|CI|CD) ]] && cat /home/webviewer.log
        exit 1
    }

log.done "GCC build completed successfully. (webviewer)"
log.sub "SAVED -> webview-app.AppDir/usr/bin/webviewer"

# localviewer.c
gcc localviewer.c -o webview-app.AppDir/usr/bin/localviewer \
    $(pkg-config --cflags --libs  webkit2gtk-4.0 gtk+-3.0) \
    -static-libgcc -static-libstdc++ &> /home/localviewer.log || {
        log.error "Compilation failed."
        log.sub "LOG: /home/localviewer.log"
        [[ $1 =~ (workflow|CI|CD) ]] && cat /home/localviewer.log
        exit 1
    }

log.done "GCC build completed successfully. (localviewer)"
log.sub "SAVED -> webview-app.AppDir/usr/bin/localviewer"

# notify.c
gcc notify.c -o webview-app.AppDir/usr/bin/notify \
    `pkg-config --cflags --libs gtk+-3.0` &> /home/notifybuild.log || {
        log.error "Compilation failed."
        log.sub "LOG: /home/notifybuild.log"
        [[ $1 =~ (workflow|CI|CD) ]] && cat /home/notifybuild.log
        exit 1
    }

log.done "GCC build completed successfully. (notify)"
log.sub "SAVED -> webview-app.AppDir/usr/bin/notify"

#---------------------------------------------------------------------

# Define the target directory
TARGET_DIR="webview-app.AppDir/usr/lib"

# Create the target directory if it doesn't exist
mkdir -p "$TARGET_DIR"

# List of library names
libs=(
    "libgio-2.0.so"
    "libglib-2.0.so"
    "libgobject-2.0.so"
    "libgtk-3.so"
    "libjavascriptcoregtk-4.0.so"
    "libwebkit2gtk-4.0.so"
)

log.info "Copying libraries to $TARGET_DIR..."

! [[ -d  webview-app.AppDir/usr/lib/webkit2gtk-4.0/ ]] && log.sub "Copying usr/lib/webkit2gtk-4.0/" && cp -r /usr/lib/webkit2gtk-4.0/ webview-app.AppDir/usr/lib

# Loop trough each library and check they are exist, if it is copy it to the target directory
for lib in "${libs[@]}"; do
    path=$(ldconfig -p | grep "$lib" | awk '{print $NF}' | head -n 1)
    if ! [[ -n "$path" ]]; then
        log.error "Warning: $lib not found at /usr/lib! install it."
        exit 1
    else
        if ! [[ -f $TARGET_DIR/$lib ]]; then
            log.sub "Copying $path"
            cp $path* $TARGET_DIR/
        else
            log.sub "$path -> pass"
        fi
    fi
done 


# Generate the AppImage and try to run
! [[ -d build ]] && mkdir build
rm build/* &> /dev/null
appimagetool webview-app.AppDir build/webview.AppImage &> /home/appimagebuild.log || {
    log.error "AppImage Build Failed"
    log.sub "LOG: /home/appimagebuild.log"
    [[ $1 =~ (workflow|CI|CD) ]] && cat /home/appimagebuild.log
    exit 1
}
log.done "AppImage build completed successfully."
log.sub "SAVED -> build/webview.AppImage"


if ! [[ $1 =~ (workflow|CI|CD) ]]; then
    log.info "Trying to run."
    ./build/webview.AppImage https://www.google.com &> /home/appimagerun.log || { 
        log.error "Run Faild, try on host machine." 
        log.sub "LOG: /home/appimagerun.log"
        [[ $1 =~ (workflow|CI|CD) ]] && cat /home/appimagerun.log
        exit 1 
    }
fi