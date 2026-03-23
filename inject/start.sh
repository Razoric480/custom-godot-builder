#!/bin/bash

cd /godot

rm -rf ./bin

echo "Compiling linux editor"

# make sure the x11 versions use the glibc 2.28 roots by godot team
export PATH=${GODOT_SDK_LINUX_X86_64}/bin:${BASE_PATH}

scons p=linuxbsd target=editor arch=x86_64 production=yes accesskit_sdk_path=/deps/accesskit/accesskit-c
strip bin/godot.linuxbsd.editor.x86_64
chmod +x bin/godot.linuxbsd.editor.x86_64

echo "Compiling linux release template"

scons p=linuxbsd target=template_debug arch=x86_64 optimize=speed disable_3d=true production=yes accesskit_sdk_path=/deps/accesskit/accesskit-c
strip bin/godot.linuxbsd.template_debug.x86_64
chmod +x bin/godot.linuxbsd.template_debug.x86_64

# restore path to use regular compilers, just in case
export PATH=${BASE_PATH}

echo "Compiling windows release template"

scons p=windows target=template_debug arch=x86_64 optimize=speed disable_3d=true production=yes d3d12=no angle_libs=/deps/angle mesa_libs=/deps/mesa accesskit_sdk_path=/deps/accesskit/accesskit-c
strip bin/godot.windows.template_debug.x86_64.exe

echo "Patching osx detect.py for modern OSXCross if needed"

# modern osxcross omits the /target prefix
sed -i 's@basecmd = root + "/target/bin/@basecmd = root + "/bin/@g' platform/macos/detect.py

echo "Compiling arm64 OSX template"

scons p=macos osxcross_sdk=darwin${OSXCROSS_SDK_VERSION} target=template_debug optimize=speed disable_3d=true arch=arm64 use_volk=no production=yes vulkan_sdk_path=/deps/moltenvk/MoltenVK/MoltenVK.xcframework angle_libs=/deps/angle accesskit_sdk_path=/deps/accesskit/accesskit-c
x86_64-apple-darwin${OSXCROSS_SDK_VERSION}-strip -u -r bin/godot.macos.template_debug.arm64

echo "Compiling x86_64 OSX template"

scons p=macos osxcross_sdk=darwin${OSXCROSS_SDK_VERSION} target=template_debug optimize=speed disable_3d=true arch=x86_64 use_volk=no production=yes vulkan_sdk_path=/deps/moltenvk/MoltenVK/MoltenVK.xcframework angle_libs=/deps/angle accesskit_sdk_path=/deps/accesskit/accesskit-c
x86_64-apple-darwin${OSXCROSS_SDK_VERSION}-strip -u -r bin/godot.macos.template_debug.x86_64

echo "Combining into universal OSX template"

lipo -create bin/godot.macos.template_debug.arm64 bin/godot.macos.template_debug.x86_64 -output bin/godot.macos.template_debug.universal

echo "Building universal bundle"

cp -r misc/dist/macos_template.app macos_template.app
mkdir -p macos_template.app/Contents/MacOS
cp bin/godot.macos.template_debug.universal macos_template.app/Contents/MacOS/godot_macos_release.universal
cp bin/godot.macos.template_debug.universal macos_template.app/Contents/MacOS/godot_macos_debug.universal
chmod +x macos_template.app/Contents/MacOS/godot_macos*
zip -q -9 -r bin/macos.zip macos_template.app

echo "Building web export"

source /emsdk/emsdk_env.sh

scons p=web target=template_debug disable_3d=true production=yes threads=no

echo "Packing result"

GODOT_VERSION=$(/usr/bin/python3 -c "import pathlib; ns={}; exec(pathlib.Path('version.py').read_text(), ns); print(f\"{ns['major']}.{ns['minor']}.{ns['patch']}\")")

zip -j /output/godot-learn.${GODOT_VERSION}.templates.zip bin/godot.windows.template_debug.x86_64.exe bin/godot.web.template_debug.wasm32.zip bin/godot.linuxbsd.template_debug.x86_64 bin/macos.zip
zip -j /output/godot-learn.${GODOT_VERSION}.editor.zip bin/godot.linuxbsd.editor.x86_64

echo "Done compiling. Archived into /output"
