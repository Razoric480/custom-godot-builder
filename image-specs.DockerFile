FROM fedora:43

ENV PATH="${PATH}:/osxcross/bin" \
  OSXCROSS_ROOT=/osxcross \
  OSXCROSS_SDK_ROOT=/osxcross/SDK/MacOSX15.4.sdk

COPY MacOSX15.4.sdk.tar.xz MacOSX15.4.sdk.tar.xz

RUN dnf install -y \

  # godot deps
  gh scons pkgconfig libX11-devel libXcursor-devel libXrandr-devel libXinerama-devel \
  libXi-devel mesa-libGL-devel mesa-libGLU-devel alsa-lib-devel pulseaudio-libs-devel \
  libudev-devel yasm gcc-c++ libstdc++-static libatomic-static \

  # windows deps
  mingw64-gcc-c++ mingw64-winpthreads-static mingw32-gcc-c++ mingw32-winpthreads-static \

  # osxcross deps
  openssl-devel clang make xz-devel libxml2-devel cmake patch cpio git bzip2 \
  bzip2-libs zlib-devel bzip2-devel && \

  # clone OSX Cross
  git clone --depth=1 https://github.com/tpoechtrager/osxcross.git "osxcross-src" && \

  # package
  mv MacOSX15.4.sdk.tar.xz osxcross-src/tarballs/MacOSX15.4.sdk.tar.xz && \
  # build
  cd osxcross-src && \
  TARGET_DIR="/osxcross" UNATTENDED=1 ./build.sh && \
  ./build_compiler_rt.sh && \
  # clean
  cd .. && rm -rf osxcross-src

CMD /bin/bash
