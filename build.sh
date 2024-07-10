#!/bin/bash
__dirname=$(cd "$(dirname "$0")"; pwd -P)
cd "${__dirname}"

flutter clean
flutter build linux

if [ -e ./dist ]; then
    rm -fr ./dist
fi

mkdir -p dist

cp -vr --preserve=links linux/AppDir dist/Thermal_Tools.AppDir

mkdir -p dist/Thermal_Tools.AppDir/bundle
cp -vr build/linux/x64/release/bundle/* dist/Thermal_Tools.AppDir/bundle

# Delete windows assets
rm -fr dist/Thermal_Tools.AppDir/bundle/data/flutter_assets/assets/windows

# Set executable flags
chmod +x dist/Thermal_Tools.AppDir/bundle/data/flutter_assets/assets/linux/exiftool/exiftool
chmod +x dist/Thermal_Tools.AppDir/bundle/data/flutter_assets/assets/linux/dji_tools/dji_irp*

if [ ! -f ./installtools/appimagetool ]; then
    wget -O ./installtools/appimagetool https://github.com/probonopd/go-appimage/releases/download/continuous/appimagetool-838-x86_64.AppImage 
    chmod +x ./installtools/appimagetool
fi

export VERSION=$(cat VERSION)
./installtools/appimagetool --overwrite ./dist/Thermal_Tools.AppDir
mv -v *.AppImage ./dist/Thermal_Tools.AppImage
