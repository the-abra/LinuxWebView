#!/bin/bash

# Load logging utilities
source lib.sh.d/log.lib
source lib.sh.d/colors.lib
# PHT Detection Warning
if [[ -f ./module.pht ]]; then
    log.warn "PHT Detected! The build process may successful but run is not guaranteed"
fi


#----------------------------/Depends Installtion\----------------------------

# Ensure GCC is installed
if ! command -v gcc; then
    log.info "Setting up dependencies..."
    
    # Update package list and install required dependencies

    if  apt update &> /dev/null && apt install -y gcc g++ make cmake file libsoup-3.0-0 zenity libsoup2.4-1 libwebkit2gtk-4.0-dev libgtk-3-dev libglib2.0-bin build-essential libfuse2 wget gstreamer1.0-libav gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly ; then
        log.error "Failed to install dependencies. Exiting..."
        log.sub "try to install manualy."
        [[ -f ./module.pht ]] && log.sub "Access to shell : pht run LinuxWebView -c bash"
        exit 1
    else
        pacman -Sy --noconfirm gcc file webkit2gtk zenity gtk3 glib2 libsoup base-devel fuse2 cmake wget  gstreamer gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav gst-plugin-gtk || {
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


#----------------------------/WebViewer Compile\----------------------------

# Compile the webviewer
log.info "Compiling the application..."


# webviewer.c
gcc $(pkg-config --cflags --libs glib-2.0) -o webview-app.AppDir/usr/bin/webviewer webviewer.c $(pkg-config --cflags --libs webkit2gtk-4.0) &> /home/webviewer.log || {
        log.error "Compilation failed."
        log.sub "LOG: /home/webviewer.log"
        [[ $1 =~ (workflow|CI|CD) ]] && cat /home/webviewer.log
        exit 1
}
log.done "GCC build completed successfully. (webviewer)"
log.sub "SAVED -> webview-app.AppDir/usr/bin/webviewer"


# webviewer-sh.c
gcc $(pkg-config --cflags --libs glib-2.0) -o webview-app.AppDir/usr/bin/webviewer-sh webviewer-sh.c $(pkg-config --cflags --libs webkit2gtk-4.0) &> /home/webviewer.log || {
        log.error "Compilation failed."
        log.sub "LOG: /home/webviewer.log"
        [[ $1 =~ (workflow|CI|CD) ]] && cat /home/webviewer.log
        exit 1
}
log.done "GCC build completed successfully. (webviewer-sh)"
log.sub "SAVED -> webview-app.AppDir/usr/bin/webviewer-sh"



#----------------------------/AppImage Depends Installation\----------------------------
if ! [[ -d webview-app.AppDir/usr/lib/webkit2gtk-4.0 ]]; then
    source lib.sh.d/copylib.sh
else
    log.info "Depends check passed."
fi


#----------------------------/AppImage Build\----------------------------

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