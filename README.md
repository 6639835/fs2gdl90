# FS2GDL90

[![Build Status](https://github.com/6639835/fs2gdl90/workflows/Build%20FS2GDL90/badge.svg)](https://github.com/6639835/fs2gdl90/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

`fs2gdl90` broadcasts simulator data over UDP in GDL90 format for EFB apps such as ForeFlight, Garmin Pilot, WingX, and FltPlan Go.

The project has two simulator frontends over a shared GDL90, ForeFlight, settings, and UDP core:

- X-Plane 12 plugin frontend for macOS, Windows, and Linux
- Microsoft Flight Simulator 2020/2024 SimConnect frontend for Windows

The current codebase includes:

- Standard GDL90 heartbeat, ownship report, and ownship geometric altitude messages
- ForeFlight ID and AHRS extension messages
- ForeFlight auto-discovery with fallback to a manual target IP/port
- X-Plane traffic from TCAS targets, with legacy multiplayer fallback
- MSFS traffic from nearby SimConnect airplane and helicopter objects
- Shared JSON settings, validation, packet encoders, UDP transport, and unit tests
- X-Plane in-sim ImGui settings window and MSFS desktop ImGui status window

## Release Installation

The recommended release layout keeps the simulator frontends separate:

```text
fs2gdl90/
|-- xplane/
|   `-- fs2gdl90/
|       |-- mac.xpl
|       `-- 64/
|           |-- win.xpl
|           `-- lin.xpl
|-- msfs/
|   |-- fs2gdl90-msfs.exe
|   `-- SimConnect.dll
|-- README.md
`-- LICENSE
```

For X-Plane, copy the packaged `xplane/fs2gdl90` folder into:

```text
X-Plane 12/Resources/plugins/
```

After launching X-Plane, open:

```text
Plugins -> FS2GDL90 -> Settings...
```

You can also toggle broadcasting from:

```text
Plugins -> FS2GDL90 -> Enable Broadcasting
```

X-Plane settings are stored in the simulator preferences directory as:

```text
Output/preferences/fs2gdl90.json
```

For MSFS, start Microsoft Flight Simulator, load a flight, then run:

```bat
msfs\fs2gdl90-msfs.exe
```

MSFS settings are stored by default under:

```text
%APPDATA%\fs2gdl90\fs2gdl90-msfs.json
```

## Quick Setup

For a basic manual setup:

1. Start the simulator frontend you use.
2. Set `Target IP` to the tablet or EFB device IP.
3. Leave `Target Port` at `4000` unless your app requires something else.
4. Keep `NIC` and `NACp` at `11`.
5. Save the settings.
6. Confirm the status view shows packets being sent.

For ForeFlight, FS2GDL90 can listen for discovery broadcasts on UDP `63093` and temporarily switch the broadcast target to the discovered host and port.

## Build From Source

The repository uses the X-Plane SDK from `SDK/`, the MSFS SimConnect SDK when building the MSFS frontend, and Dear ImGui under `third_party/imgui`.

Clone with submodules:

```bash
git clone --recursive https://github.com/6639835/fs2gdl90.git
cd fs2gdl90
```

### Prerequisites

- CMake 3.16+
- C++17 compiler
- X-Plane SDK headers and libraries in `SDK/` for the X-Plane frontend
- MSFS SDK with SimConnect for the MSFS frontend
- OpenGL development libraries on Linux

Platform notes:

- macOS: Xcode Command Line Tools
- Windows: Visual Studio 2022 or a compatible MSVC toolchain
- Linux: GCC 7+ or Clang 6+ plus OpenGL development packages

### X-Plane Frontend

The X-Plane frontend is enabled by default:

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --target fs2gdl90_xplane --config Release
```

Expected output locations:

- macOS: `build/mac.xpl`
- Linux: `build/lin.xpl`
- Windows: `build/win.xpl` or `build/Release/win.xpl` depending on generator

### MSFS Frontend

Build the MSFS frontend on Windows with the MSFS SDK installed:

```bat
cmake -S . -B build-msfs -G "Visual Studio 17 2022" ^
  -DFS2GDL90_BUILD_XPLANE=OFF ^
  -DFS2GDL90_BUILD_MSFS=ON ^
  -DMSFS_SDK_PATH="C:\MSFS SDK"
cmake --build build-msfs --config Release --target fs2gdl90_msfs
```

`MSFS_SDK_PATH` should point to the SDK root that contains `SimConnect SDK\include\SimConnect.h` and `SimConnect SDK\lib\SimConnect.lib`. Building against the MSFS 2020 SDK is recommended for one binary that can run with MSFS 2020 and MSFS 2024.

For source builds, run:

```bat
build-msfs\Release\fs2gdl90-msfs.exe
```

Optional overrides:

```bat
fs2gdl90-msfs.exe --config C:\path\fs2gdl90-msfs.json --target-ip 192.168.1.50 --target-port 4000
```

## Testing

Enable the test target with:

```bash
cmake -S . -B build -DFS2GDL90_BUILD_XPLANE=OFF -DFS2GDL90_BUILD_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
cmake --build build --target fs2gdl90_tests --config Debug
ctest --test-dir build --output-on-failure
```

A coverage helper is available at `scripts/coverage.sh`. It configures a separate coverage build under `build/coverage`, runs `ctest`, and reports line and function coverage for `src/`. By default it enforces at least `97.5%` line coverage and `100%` function coverage, and you can override those thresholds with `MIN_LINES_PERCENT` and `MIN_FUNCTIONS_PERCENT`.

## Runtime Behavior

Both simulator frontends send:

- `0x00` Heartbeat at the configured `heartbeat_rate`
- `0x0A` Ownship Report at the configured `position_rate`
- `0x0B` Ownship Geometric Altitude at 1 Hz
- `0x14` Traffic Report at 1 Hz
- `0x65/0x00` ForeFlight ID at 1 Hz
- `0x65/0x01` ForeFlight AHRS at 5 Hz

Current X-Plane behavior:

- ForeFlight auto-discovery is optional and listens on the configured broadcast port
- Manual `target_ip` and `target_port` are used as the fallback target
- The effective callsign uses the aircraft tail number when available, otherwise the configured fallback callsign
- Ownship report altitude uses `sim/cockpit2/gauges/indicators/altitude_ft_pilot` when available
- AHRS heading can be transmitted as true or magnetic heading
- Traffic is sourced from TCAS target datarefs when available, otherwise from legacy multiplayer datarefs

Current MSFS behavior:

- Connects to MSFS 2020/2024 through SimConnect from an external Windows executable
- Uses the same JSON settings schema as the X-Plane frontend
- Sends ownship GDL90 position, geometric altitude, ForeFlight device info, and ForeFlight AHRS
- Uses ForeFlight discovery on UDP `63093` when enabled
- Requests nearby SimConnect airplane and helicopter traffic once per second and sends best-effort GDL90 traffic reports
- Includes traffic injected by clients such as vPilot because those clients create/update nearby VATSIM aircraft as SimConnect AI sim objects
- Generates synthetic self-assigned traffic addresses when MSFS does not expose real ICAO addresses

Weather uplink data is not transmitted.

## Configuration

The on-disk settings file is JSON:

```json
{
  "target_ip": "192.168.1.100",
  "target_port": 4000,
  "foreflight_auto_discovery": true,
  "foreflight_broadcast_port": 63093,
  "icao_address": 11259375,
  "callsign": "N12345",
  "emitter_category": 1,
  "device_name": "FS2GDL90",
  "device_long_name": "FS2GDL90 AHRS",
  "internet_policy": 0,
  "ahrs_use_magnetic_heading": false,
  "heartbeat_rate": 1.0,
  "position_rate": 2.0,
  "nic": 11,
  "nacp": 11,
  "debug_logging": false,
  "log_messages": false
}
```

Field reference:

| Key | Type | Notes |
| --- | --- | --- |
| `target_ip` | string | Manual UDP target. Can be a unicast address, subnet broadcast, or `255.255.255.255`. |
| `target_port` | number | Manual UDP destination port. |
| `foreflight_auto_discovery` | boolean | Enables the listener for ForeFlight discovery broadcasts. |
| `foreflight_broadcast_port` | number | Discovery listen port. Default is `63093`. |
| `icao_address` | number | Stored in JSON as a decimal 24-bit value. The UI accepts hex such as `0xABCDEF`. |
| `callsign` | string | Fallback only. Trimmed to 8 characters. |
| `emitter_category` | number | Valid range `0-39`. |
| `device_name` | string | ForeFlight device name. Trimmed to 8 characters. |
| `device_long_name` | string | ForeFlight long name. Trimmed to 16 characters. |
| `internet_policy` | number | `0=Unrestricted`, `1=Expensive`, `2=Disallowed`. |
| `ahrs_use_magnetic_heading` | boolean | `false` sends true heading, `true` converts to magnetic heading. |
| `heartbeat_rate` | number | Must be greater than `0`. |
| `position_rate` | number | Must be greater than `0`. |
| `nic` | number | Valid range `0-11`. `11` is recommended for EFB compatibility. |
| `nacp` | number | Valid range `0-11`. `11` is recommended for EFB compatibility. |
| `debug_logging` | boolean | Enables debug logging. |
| `log_messages` | boolean | Enables raw message logging. |

## Data Sources

Key X-Plane datarefs used by the plugin include:

- `sim/flightmodel/position/latitude`
- `sim/flightmodel/position/longitude`
- `sim/flightmodel/position/elevation`
- `sim/cockpit2/gauges/indicators/altitude_ft_pilot`
- `sim/flightmodel/position/groundspeed`
- `sim/flightmodel/position/true_psi`
- `sim/flightmodel/position/theta`
- `sim/flightmodel/position/phi`
- `sim/flightmodel/position/psi`
- `sim/flightmodel/position/indicated_airspeed`
- `sim/flightmodel/position/true_airspeed`
- `sim/flightmodel/position/vh_ind_fpm`
- `sim/flightmodel/failures/onground_any`
- `sim/aircraft/view/acf_tailnum`
- `sim/cockpit2/tcas/targets/*`
- `sim/multiplayer/position/planeN_*`

Key MSFS SimVars used by the frontend include:

- `PLANE LATITUDE`
- `PLANE LONGITUDE`
- `PLANE ALTITUDE`
- `PRESSURE ALTITUDE`
- `GROUND VELOCITY`
- `VERTICAL SPEED`
- `PLANE HEADING DEGREES TRUE`
- `PLANE HEADING DEGREES MAGNETIC`
- `PLANE PITCH DEGREES`
- `PLANE BANK DEGREES`
- `AIRSPEED INDICATED`
- `AIRSPEED TRUE`
- `SIM ON GROUND`
- `ATC ID`
- `VELOCITY WORLD X/Y/Z` for traffic track and vertical speed

## Repository Layout

```text
.
|-- CMakeLists.txt
|-- SDK/
|-- docs/
|-- include/fs2gdl90/
|-- src/
|   |-- core/
|   |-- msfs/
|   `-- xplane/
|-- tests/
`-- third_party/imgui/
```

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
