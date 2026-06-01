#!/bin/bash
# Build script for Linux

echo "========================================="
echo "Building fs2gdl90 for Linux"
echo "========================================="

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Create build directory if it doesn't exist
if [ ! -d "build" ]; then
    echo "Creating build directory..."
    mkdir build
fi

cd build

# Configure with CMake
echo ""
echo "Configuring with CMake..."
cmake .. -DCMAKE_BUILD_TYPE=Release

if [ $? -ne 0 ]; then
    echo ""
    echo "[ERROR] Configuration failed!"
    exit 1
fi

# Build the X-Plane frontend
echo ""
echo "Building X-Plane frontend..."
cmake --build . --target fs2gdl90_xplane --config Release

if [ $? -ne 0 ]; then
    echo ""
    echo "[ERROR] Build failed!"
    exit 1
fi

echo ""
echo "========================================="
echo "[SUCCESS] Build successful!"
echo "========================================="
echo "Output: build/lin.xpl"
echo ""
echo "To install the X-Plane frontend, copy the following to your X-Plane/Resources/plugins/ directory:"
echo "  - build/lin.xpl"
echo "  - (settings saved at runtime to Output/preferences/fs2gdl90.json)"
echo "========================================="
