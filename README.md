# LinuxWebView
Web View System for Linux

---

# 📌 **Dependencies & Setup**  

## 🔗 **Dependencies**  
Before building and running the project, ensure the following dependencies are installed:  

### **Required Packages:**  
| Dependency               | Description                                      |
|--------------------------|--------------------------------------------------|
| **appimagetool**         | Tool for creating AppImage packages             |
| **bash**                 | Command-line shell                              |
| **func4bash**            | Utility functions for Bash (from [the-abra/func4bash](https://github.com/the-abra/func4bash)) |
| **gcc**                  | GNU C compiler                                  |
| **webkit2gtk**           | Web rendering engine                            |
| **gtk3**                 | GUI toolkit for Linux applications              |
| **base-devel**           | Essential development tools                     |
| **cmake**                | Cross-platform build system                     |
| **wget**                 | File downloader for retrieving dependencies     |

---


## ⚙️ **Setup**  

Run the following command to install dependencies and set up the project:  
```bash
./main.sh
```

This script will:  
✔️ Install missing dependencies  
✔️ Download & configure **AppImageTool**  
✔️ Compile the project  



## Manuel Installation

    pacman -Sy --noconfirm gcc webkit2gtk gtk3 flatpak flatpak-builder git base-devel fuse2 cmake wget || exit 1
    
### Download and set up AppImageTool
    echo -e "Downloading AppImageTool..."
    APPIMAGE_TOOL="/usr/local/bin/appimagetool"
    wget -q https://github.com/AppImage/AppImageKit/releases/latest/download/appimagetool-x86_64.AppImage -O "$APPIMAGE_TOOL" || {
            log.error "Failed to download AppImageTool. Exiting..."
            exit 1
            }
    chmod +x $APPIMAGE_TOOL

### Create webview-app.AppDir if doesn't exist
    chmod +x "$APPIMAGE_TOOL"
    mkdir -p webview-app.AppDir/usr/bin
    mkdir -p webview-app.AppDir/usr/share/applications
    mkdir -p webview-app.AppDir/usr/share/icons
    echo -e "AppImageTool installed successfully."   


Once set up, you can run the application with:  
```bash
bash main.sh
```

## ✅ How to Trigger the Release

Push a new version with tag:

    git add .
    git commit -m "Your commit message"

    git tag -a v1.x -m "Release version 1.x"

    git push origin v1.x

## ✅ How to Delete the Tag

    git tag -d v1.0.1          # Delete local tag
    git push origin --delete v1.0.1  # Delete remote tag
    

This will automatically build and release your AppImage! 🚀
