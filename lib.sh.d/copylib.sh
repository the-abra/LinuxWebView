#!/bin/bash

# Target directory for copied libraries and dependencies
TARGET_DIR="webview-app.AppDir"

# Function to list, copy dependencies for a given library pattern
copy_dependencies() {
  log.info "Checking and copying dependencies for pattern: $1"
  
  # Get the list of libraries matching the pattern
  libs=$(ldconfig -p | grep "$1" | awk '{print $NF}')
  
  # For each library found, copy it and its dependencies
  for lib in $libs; do
    # Get the directory of the library
    lib_dir=$(dirname "$lib")
    
    # Ensure the target directory structure exists
    mkdir -p "$TARGET_DIR$lib_dir"
    
    # Copy the library to the target directory
    #log.sub "Copying $lib to $TARGET_DIR$lib_dir"
    cp -v "$lib" "$TARGET_DIR$lib_dir/" &> /dev/null
    
    # Get the ldd output and loop through its dependencies
    for dep in $(ldd "$lib" | grep "=> /" | awk '{print $3}'); do
      # Ensure the directory structure for the dependency exists
      dep_dir=$(dirname "$dep")
      mkdir -p "$TARGET_DIR$dep_dir"
      
      # Copy the dependency to the target directory
      #log.sub "Copying dependency $dep to $TARGET_DIR$dep_dir"
      cp -v "$dep" "$TARGET_DIR$dep_dir/" &> /dev/null
    done
  done
}

# Create the target directory structure if it doesn't exist
mkdir -p "$TARGET_DIR"

# List and copy dependencies for GTK, WebKitGTK, GIO, and GLib
copy_dependencies "gtk"
copy_dependencies "webkit"
copy_dependencies "gio"
copy_dependencies "glib"

cp -r /usr/lib/webkit2gtk-4.0/ webview-app.AppDir/usr/lib/

echo "All libraries and their dependencies copied to $TARGET_DIR"
