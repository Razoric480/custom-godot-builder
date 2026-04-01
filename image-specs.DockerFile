FROM fedora:43

ENV GODOT_SDK_LINUX_X86_64=/x86_64-godot-linux-gnu_sdk-buildroot \
  PATH="/osxcross/bin:${PATH}" \
  BASE_PATH=/osxcross/bin:/root/.local/bin:/root/bin:/usr/local/bin:/usr/bin \
  OSXCROSS_ROOT=/osxcross \
  OSXCROSS_SDK_ROOT=/osxcross/SDK/MacOSX${OSX_SDK_VERSION}.sdk \
  ANGLE_BASE=https://github.com/godotengine/godot-angle-static/releases/download/chromium%2F7578/godot-angle-static \
  MESA_BASE=https://github.com/godotengine/godot-nir-static/releases/download/25.3.1-1/godot-nir-static

COPY bootstrap.sh bootstrap.sh
COPY MacOSX${OSX_SDK_VERSION}.sdk.tar.xz MacOSX${OSX_SDK_VERSION}.sdk.tar.xz

RUN dnf install -y --setopt=install_weak_deps=False \
  # base
  bash binutils bzip2 curl file findutils gettext git make nano patch pkgconfig python3-pip unzip which xz 7z \

  # windows
  mingw32-gcc mingw32-gcc-c++ mingw32-winpthreads-static mingw64-gcc mingw64-gcc-c++ mingw64-winpthreads-static \

  # osxcross
  automake autoconf bzip2-devel cmake gcc gcc-c++ libdispatch libicu-devel libtool \
  libxml2-devel openssl-devel uuid-devel yasm \

  # web
  libatomic && \

  pip install scons==4.10.0 && \

  # linux build root
  curl -LO https://github.com/godotengine/buildroot/releases/download/godot-2023.08.x-4/x86_64-godot-linux-gnu_sdk-buildroot.tar.bz2 && \
  tar xf x86_64-godot-linux-gnu_sdk-buildroot.tar.bz2 && \
  rm -f x86_64-godot-linux-gnu_sdk-buildroot.tar.bz2 && \
  pushd x86_64-godot-linux-gnu_sdk-buildroot && \
  ./relocate-sdk.sh && \
  popd && \

  # clone OSX Cross
  git clone --depth=1 https://github.com/tpoechtrager/osxcross.git "osxcross-src" && \
  # package
  mv MacOSX${OSX_SDK_VERSION}.sdk.tar.xz osxcross-src/tarballs/MacOSX${OSX_SDK_VERSION}.sdk.tar.xz && \
  # build OSXCross and apple clang
  pushd /osxcross-src && UNATTENDED=1 ENABLE_CLANG_INSTALL=1 INSTALLPREFIX=/usr ./build_apple_clang.sh && \
  TARGET_DIR="/osxcross" UNATTENDED=1 ./build.sh && ./build_compiler_rt.sh && \
  popd && rm -rf osxcross-src && \

  # emscripten
  git clone -b ${EMSCRIPTEN_VERSION} --depth=1 --single-branch https://github.com/emscripten-core/emsdk.git && pushd emsdk && \
  git pull && rm -rf .git && ./emsdk install ${EMSCRIPTEN_VERSION} && ./emsdk activate ${EMSCRIPTEN_VERSION} && \

  popd && mkdir output && chmod +x bootstrap.sh && \

  # moltenVK
  mkdir -p /deps/moltenvk && pushd /deps/moltenvk && curl -LO https://github.com/godotengine/moltenvk-osxcross/releases/download/moltenvk-1.4.1/MoltenVK-all.tar.xz && \
  tar xvf MoltenVK-all.tar.xz && rm -f MoltenVK-all.tar.xz && mv MoltenVK/MoltenVK/include/ MoltenVK/ && mv MoltenVK/MoltenVK/static/MoltenVK.xcframework/ MoltenVK/ && popd && \

  # accesskit
  mkdir /deps/accesskit && pushd /deps/accesskit && curl -L -o accesskit.zip https://github.com/godotengine/godot-accesskit-c-static/releases/download/0.18.0/accesskit-c-0.21.2.zip && \
  unzip -o accesskit.zip && rm -f accesskit.zip && mv accesskit-c-* accesskit-c && popd && \

  # angle
  mkdir /deps/angle && pushd /deps/angle && \
  curl -L -o windows_arm64.zip ${ANGLE_BASE}-arm64-llvm-release.zip && \
  curl -L -o windows_x86_64.zip ${ANGLE_BASE}-x86_64-gcc-13-release.zip && \
  curl -L -o windows_x86_32.zip ${ANGLE_BASE}-x86_32-gcc-13-release.zip && \
  curl -L -o macos_arm64.zip ${ANGLE_BASE}-arm64-macos-release.zip && \
  curl -L -o macos_x86_64.zip ${ANGLE_BASE}-x86_64-macos-release.zip && \
  unzip -o windows_arm64.zip && rm -f windows_arm64.zip && \
  unzip -o windows_x86_64.zip && rm -f windows_x86_64.zip && \
  unzip -o windows_x86_32.zip && rm -f windows_x86_32.zip && \
  unzip -o macos_arm64.zip && rm -f macos_arm64.zip && \
  unzip -o macos_x86_64.zip && rm -f macos_x86_64.zip && \
  popd && \

  # mesa
  mkdir -p /deps/mesa && pushd /deps/mesa && \
  curl -L -o mesa_arm64.zip ${MESA_BASE}-arm64-llvm-release.zip && \
  curl -L -o mesa_x86_64.zip ${MESA_BASE}-x86_64-gcc-release.zip && \
  curl -L -o mesa_x86_32.zip ${MESA_BASE}-x86_32-gcc-release.zip && \
  unzip -o mesa_arm64.zip && rm -f mesa_arm64.zip && \
  unzip -o mesa_x86_64.zip && rm -f mesa_x86_64.zip && \
  unzip -o mesa_x86_32.zip && rm -f mesa_x86_32.zip && \
  popd

CMD ["/bootstrap.sh"]
