# ghammer Linux (amd64) static build image

FROM ubuntu:22.04@sha256:45e9ddc6895604674618a409ca9f73d301da8fdb75fe330e8e9a27b3b219e4ad

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]
ARG JOBS=8
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl xz-utils make perl python3 pkg-config ninja-build meson bison gperf \
      gcc-12 g++-12 rapidjson-dev libssl-dev \
      libxcb1-dev libxcb-randr0-dev libxcb-render0-dev libxcb-shape0-dev libxcb-shm0-dev \
      libxcb-sync-dev libxcb-xfixes0-dev libxcb-xkb-dev libxcb-xinput-dev \
      libwayland-dev \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 100 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 100 \
    && update-alternatives --install /usr/bin/cc cc /usr/bin/gcc-12 100 \
    && update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++-12 100

RUN printf '#!/bin/bash\nset -euo pipefail\ncurl -fsSL --retry 3 -o "$2" "$1"\necho "$3  $2" | sha256sum -c -\n' \
      > /usr/local/bin/fetch && chmod +x /usr/local/bin/fetch

RUN cd /tmp \
    && fetch https://github.com/Kitware/CMake/releases/download/v3.31.9/cmake-3.31.9-linux-x86_64.tar.gz \
         cmake.tar.gz 312d78e0b7c5c9b4a97a87a46c3e525aa84895fe8135c238c4616bba73dc9518 \
    && mkdir /opt/cmake && tar xf cmake.tar.gz -C /opt/cmake --strip-components=1 && rm cmake.tar.gz \
    && ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake

ENV QT_TAR=/opt/qt-src/qt-everywhere-src-6.9.3.tar.xz
RUN --mount=type=cache,id=qt-src,target=/opt/qt-src \
    [ -f $QT_TAR ] || fetch https://download.qt.io/archive/qt/6.9/6.9.3/single/qt-everywhere-src-6.9.3.tar.xz $QT_TAR 59d4fbf50d2524a9082f85d565f0197316cde89c26e97cfc6c157cb255b7ea18

ENV DEPS=/opt/ghammer/deps
ENV LINK_TAIL="/opt/ghammer/deps/lib/libfontconfig.a /opt/ghammer/deps/lib/libfreetype.a /opt/ghammer/deps/lib/libexpat.a /opt/ghammer/deps/lib/libpng16.a /opt/ghammer/deps/lib/libz.a -ldl -lpthread"
ENV CMAKE_PREFIX_PATH=/opt/ghammer/qt;/opt/ghammer/deps \
    PKG_CONFIG_PATH=/opt/ghammer/deps/lib/pkgconfig:/opt/ghammer/deps/share/pkgconfig \
    CFLAGS="-O2 -fPIC" CXXFLAGS="-O2 -fPIC"

RUN cd /tmp && X=https://xorg.freedesktop.org/releases/individual/lib \
    && cm() { cmake -S "$1" -B "$1/b" -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$DEPS \
                -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DBUILD_SHARED_LIBS=OFF "${@:2}" \
              && cmake --build "$1/b" -j$JOBS && cmake --install "$1/b"; } \
    && ac() { (cd "$1" && ./configure --prefix=$DEPS --libdir=$DEPS/lib --enable-static --disable-shared --with-pic \
               && make -j$JOBS install); } \
    \
    && fetch https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.xz z.tar.xz \
         38ef96b8dfe510d42707d9c781877914792541133e1870841463bfa73f883e32 \
    && tar xf z.tar.xz && cm zlib-1.3.1 -DZLIB_BUILD_EXAMPLES=OFF && rm -f $DEPS/lib/libz.so* \
    \
    && fetch https://download.sourceforge.net/libpng/libpng-1.6.50.tar.xz png.tar.xz \
         4df396518620a7aa3651443e87d1b2862e4e88cad135a8b93423e01706232307 \
    && tar xf png.tar.xz && cm libpng-1.6.50 -DPNG_SHARED=OFF -DPNG_STATIC=ON -DPNG_TESTS=OFF -DPNG_TOOLS=OFF \
         -DPNG_EXECUTABLES=OFF -DPNG_FRAMEWORK=OFF -DZLIB_ROOT=$DEPS \
    \
    && fetch https://github.com/libexpat/libexpat/releases/download/R_2_7_1/expat-2.7.1.tar.xz expat.tar.xz \
         354552544b8f99012e5062f7d570ec77f14b412a3ff5c7d8d0dae62c0d217c30 \
    && tar xf expat.tar.xz && cm expat-2.7.1 -DEXPAT_SHARED_LIBS=OFF -DEXPAT_BUILD_TOOLS=OFF \
         -DEXPAT_BUILD_EXAMPLES=OFF -DEXPAT_BUILD_TESTS=OFF -DEXPAT_BUILD_DOCS=OFF -DEXPAT_BUILD_FUZZERS=OFF \
    \
    && fetch https://download.savannah.gnu.org/releases/freetype/freetype-2.13.3.tar.xz ft.tar.xz \
         0550350666d427c74daeb85d5ac7bb353acba5f76956395995311a9c6f063289 \
    && tar xf ft.tar.xz && cm freetype-2.13.3 -DFT_DISABLE_BZIP2=ON -DFT_DISABLE_BROTLI=ON \
         -DFT_DISABLE_HARFBUZZ=ON -DFT_DISABLE_PNG=ON -DFT_REQUIRE_ZLIB=ON \
    \
    && fetch https://github.com/KhronosGroup/Vulkan-Headers/archive/refs/tags/v1.3.296.tar.gz vk.tar.gz \
         e204e0b3c19f622d197df945737f5db913d6621830999b8578d34e80a7c90585 \
    && tar xf vk.tar.gz && cm Vulkan-Headers-1.3.296 -DVULKAN_HEADERS_ENABLE_MODULE=OFF -DVULKAN_HEADERS_ENABLE_TESTS=OFF \
    \
    && fetch https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.15.0.tar.xz fc.tar.xz \
         63a0658d0e06e0fa886106452b58ef04f21f58202ea02a94c39de0d3335d7c0e \
    && tar xf fc.tar.xz \
    && meson setup fontconfig-2.15.0/b fontconfig-2.15.0 --prefix=$DEPS --libdir=lib --buildtype=release \
         --default-library=static --wrap-mode=nofallback --sysconfdir=/etc --localstatedir=/var \
         -Ddoc=disabled -Dnls=disabled -Dtests=disabled -Dtools=disabled -Dcache-build=disabled \
    && ninja -C fontconfig-2.15.0/b -j$JOBS && meson install -C fontconfig-2.15.0/b \
    \
    && fetch https://xkbcommon.org/download/libxkbcommon-1.7.0.tar.xz xkb.tar.xz \
         65782f0a10a4b455af9c6baab7040e2f537520caa2ec2092805cdfd36863b247 \
    && tar xf xkb.tar.xz \
    && meson setup libxkbcommon-1.7.0/b libxkbcommon-1.7.0 --prefix=$DEPS --libdir=lib --buildtype=release \
         --default-library=static -Denable-x11=true -Denable-wayland=false -Denable-docs=false \
         -Denable-tools=false -Denable-xkbregistry=false -Denable-bash-completion=false \
         -Dxkb-config-root=/usr/share/X11/xkb -Dx-locale-root=/usr/share/X11/locale \
    && ninja -C libxkbcommon-1.7.0/b -j$JOBS && meson install -C libxkbcommon-1.7.0/b \
    \
    && fetch $X/xcb-util-0.4.1.tar.xz u.tar.xz 5abe3bbbd8e54f0fa3ec945291b7e8fa8cfd3cccc43718f8758430f94126e512 \
    && fetch $X/xcb-util-image-0.4.1.tar.xz i.tar.xz ccad8ee5dadb1271fd4727ad14d9bd77a64e505608766c4e98267d9aede40d3d \
    && fetch $X/xcb-util-keysyms-0.4.1.tar.xz k.tar.xz 7c260a5294412aed429df1da2f8afd3bd07b7cba3fec772fba15a613a6d5c638 \
    && fetch $X/xcb-util-renderutil-0.3.10.tar.xz r.tar.xz 3e15d4f0e22d8ddbfbb9f5d77db43eacd7a304029bf25a6166cc63caa96d04ba \
    && fetch $X/xcb-util-wm-0.4.2.tar.xz w.tar.xz 62c34e21d06264687faea7edbf63632c9f04d55e72114aa4a57bb95e4f888a0b \
    && fetch $X/xcb-util-cursor-0.1.5.tar.xz c.tar.xz 0caf99b0d60970f81ce41c7ba694e5eaaf833227bb2cbcdb2f6dc9666a663c57 \
    && for f in u i k r w c; do tar xf $f.tar.xz; done \
    && ac xcb-util-0.4.1 && ac xcb-util-image-0.4.1 && ac xcb-util-keysyms-0.4.1 \
    && ac xcb-util-renderutil-0.3.10 && ac xcb-util-wm-0.4.2 && ac xcb-util-cursor-0.1.5 \
    && mkdir xu && (cd xu && ar x $DEPS/lib/libxcb-util.a && ar rs $DEPS/lib/libxcb-image.a *.o) \
    && rm -rf /tmp/*

RUN --mount=type=cache,id=qt-src,target=/opt/qt-src cd /tmp \
    && ([ -f $QT_TAR ] || fetch https://download.qt.io/archive/qt/6.9/6.9.3/single/qt-everywhere-src-6.9.3.tar.xz $QT_TAR 59d4fbf50d2524a9082f85d565f0197316cde89c26e97cfc6c157cb255b7ea18) \
    && tar xf $QT_TAR -C /tmp \
    && mkdir qt-build && cd qt-build \
    && /tmp/qt-everywhere-src-6.9.3/configure -prefix /opt/ghammer/qt -static -release -opensource -confirm-license \
         -submodules qtbase,qtdeclarative,qtshadertools,qtsvg,qtimageformats,qtwebsockets,qthttpserver,qtwayland \
         -nomake examples -nomake tests \
         -xcb -feature-wayland -fontconfig -system-freetype -qt-harfbuzz -system-zlib -system-libpng -qt-libjpeg \
         -qt-pcre -sql-sqlite -qt-sqlite -no-opengl -feature-vulkan \
         -dbus-runtime -openssl-runtime -no-icu -no-glib -no-feature-xlib -no-feature-wayland-server \
         -- -DCMAKE_PREFIX_PATH=$DEPS -DCMAKE_C_COMPILER=gcc-12 -DCMAKE_CXX_COMPILER=g++-12 \
            "-DCMAKE_C_STANDARD_LIBRARIES=$LINK_TAIL" "-DCMAKE_CXX_STANDARD_LIBRARIES=$LINK_TAIL" \
    && cmake --build . --parallel $JOBS && cmake --install . \
    && cd / && rm -rf /tmp/* $QT_TAR

ENV PATH=/opt/ghammer/qt/bin:$PATH

RUN apt-get update && apt-get install -y --no-install-recommends libglm-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
CMD ["bash", "-c", "cmake -S /src -B /out/build-linux-amd64 -GNinja -C /src/cmake/linux-static.cmake && cmake --build /out/build-linux-amd64 -j8 --target client server"]
