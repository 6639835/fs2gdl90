@echo off
REM Build script for Windows

echo =========================================
echo Building fs2gdl90 for Windows
echo =========================================

REM Change to script directory
cd /d "%~dp0"

REM Create build directory if it doesn't exist
if not exist "build" (
    echo Creating build directory...
    mkdir build
)

cd build

REM Configure with CMake
echo.
echo Configuring with CMake...
cmake .. -G "Visual Studio 17 2022" -A x64

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Configuration failed!
    exit /b 1
)

REM Build the X-Plane frontend
echo.
echo Building X-Plane frontend...
cmake --build . --target fs2gdl90_xplane --config Release

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Build failed!
    exit /b 1
)

echo.
echo =========================================
echo [SUCCESS] Build successful!
echo =========================================
echo Output: build\Release\win.xpl
echo.
echo To install the X-Plane frontend, copy the following to your X-Plane\Resources\plugins\ directory:
echo   - build\Release\win.xpl
echo   - (settings saved at runtime to Output\preferences\fs2gdl90.json)
echo =========================================

pause
