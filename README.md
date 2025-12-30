# Thermal Tools

A tool to convert DJI thermal images to plain 32bit float TIFFs for use with [WebODM](https://webodm.net).

![Thermal Tool](https://github.com/uav4geo/Thermal-Tools/assets/1951843/41edbc20-d779-45c3-b513-db8fdcbb5c7a)

## Usage

### Windows

 * Download and install https://github.com/uav4geo/Thermal-Tools/releases/download/v1.2.0/Thermal_Tools_Setup.exe

### Linux

 * Download https://github.com/uav4geo/Thermal-Tools/releases/download/v1.2.0/Thermal_Tools.AppImage
 * Run: `chmod +x ./Thermal_Tools.AppImage && ./Thermal_Tools.AppImage`

Afterwards:

 * Select a folder with thermal images captured with a DJI drone
 * Optionally set environment parameters
 * Press "Process"

:warning: When processing the resulting images with WebODM, make sure you **don't** select the *radiometric-calibration* option. The images processed with this software are already calibrated. 

## Supported Drones

 * Zenmuse H20N
 * Zenmuse H20 Series
 * Matrice 30 Series
 * Zenmuse XT S
 * Zenmuse H30 Series
 * Mavic 2 Enterprise Advanced
 * DJI Mavic 3 Enterprise

## Supported Platforms

 * Windows 
 * Linux

Unfortunately DJI does not provide binaries for macOS, so this application cannot work on macOS.

## Build

You'll need to install https://docs.flutter.dev/get-started/install, then:

```bash
flutter build windows
```

Or

```bash
flutter build linux
```
## Development

Install [FVM](https://fvm.app/) and run:

```bash
fvm flutter pub get
```

You can run the application in development mode by running:

```bash
fvm flutter run
```

## Contributions

We welcome contributions! Feel free to open pull requests.

## Licenses

 - This code, not including the DJI Thermal SDK and Exiftool is licensed under the AGPLv3
 - The DJI Thermal SDK binaries are proprietary. See https://www.dji.com/downloads/softwares/dji-thermal-sdk for licensing details.
 - ExifTool is licensed under the GPLv3
