#!/bin/bash
#
# build_android.sh
# Copyright (c) 2012 Jacek Marchwicki
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# =======================================================================
#   Customize FFmpeg build
#       Comment out what you do not need, specifying 'no' will not
#       disable them.
#
#   Building with x264
#       Will not work for armv5
ENABLE_X264=yes

#   Toolchain version
#       Comment out if you want default or specify a version
#       Default takes the highest toolchain version from NDK
# TOOLCHAIN_VER=4.6

#   Use fdk-aac instead of vo-amrwbenc
#       Default uses vo-amrwbenc and it is worse than fdk-aac but
#       because of licensing, it requires you to build FFmpeg from
#       scratch if you want to use fdk-aac. Uncomment to use fdk-aac
# PREFER_FDK_AAC=yes

#
# =======================================================================

if [ -n $(which ndk-build) ]; then
    NDK=$(dirname $(which ndk-build))
elif [ -z "$NDK" ]; then
    echo NDK variable not set or in path, exiting
    echo "   Example: export NDK=/your/path/to/android-ndk"
    echo "   Or add your ndk path to ~/.bashrc"
    echo "   Then run ./build_android.sh"
    exit 1
fi

# Check the Application.mk for the architectures we need to compile for
while read line; do
    if [[ $line =~ ^APP_ABI\ *?:= ]]; then
        archs=(${line#*=})
        if [[ " ${archs[*]} " == *" all "* ]]; then
            build_all=true
        fi
        break
    fi
done <"../VPlayer_library/jni/Application.mk"
if [ -z "$archs" ]; then
    echo "Application.mk has not specified any architecture, please use 'APP_ABI:=<ARCH>'"
    exit 1
else
    echo "Building for the following architectures: "${archs[@]}
fi

# Get the platform version from Application.mk
PLATFORM_VERSION=9
while read line; do
    if [[ $line =~ ^APP_PLATFORM\ *?:= ]]; then
        PLATFORM_VERSION=${line#*-}
        break
    fi
done <"../VPlayer_library/jni/Application.mk"
echo Trying to find $NDK/platforms/android-$PLATFORM_VERSION
if [ ! -d "$NDK/platforms/android-$PLATFORM_VERSION" ]; then
    echo "Android platform doesn't exist, try to find a lower version than" $PLATFORM_VERSION
    while [ $PLATFORM_VERSION -gt 0 ]; do
        if [ -d "$NDK/platforms/android-$PLATFORM_VERSION" ]; then
            break
        fi
        let PLATFORM_VERSION=PLATFORM_VERSION-1
    done
    if [ ! -d "$NDK/platforms/android-$PLATFORM_VERSION" ]; then
        echo Cannot find any valid Android platforms inside $NDK/platforms/
        exit 1
    fi
fi
echo Using Android platform from $NDK/platforms/android-$PLATFORM_VERSION
PLATFORM_VERSION=android-$PLATFORM_VERSION

# Get the newest arm-linux-androideabi version
if [ -z "$TOOLCHAIN_VER" ]; then
    folders=$NDK/toolchains/arm-linux-androideabi-*
    for i in $folders; do
        n=${i#*$NDK/toolchains/arm-linux-androideabi-}
        reg='.*?[a-zA-Z].*?'
        if ! [[ $n =~ $reg ]] ; then
            TOOLCHAIN_VER=$n
        fi
    done
    if [ ! -d $NDK/toolchains/arm-linux-androideabi-$TOOLCHAIN_VER ]; then
        echo $NDK/toolchains/arm-linux-androideabi-$TOOLCHAIN_VER does not exist
        exit 1
    fi
fi
echo Using $NDK/toolchains/{ARCH}-$TOOLCHAIN_VER

# Read from the Android.mk file to build subtitles (fribidi, libpng, freetype2, libass)
while read line; do
    if [[ $line =~ ^SUBTITLES\ *?:= ]]; then
        echo "Going to build with subtitles"
        BUILD_WITH_SUBS=true
    fi
done <"../VPlayer_library/jni/Android.mk"

OS=`uname -s | tr '[A-Z]' '[a-z]'`
function build_x264
{
    find x264/ -name "*.o" -type f -delete
    if [ ! -z "$ENABLE_X264" ]; then
        PLATFORM=$NDK/platforms/$PLATFORM_VERSION/arch-$ARCH/
        export PATH=${PATH}:$PREBUILT/bin/
        CROSS_COMPILE=$PREBUILT/bin/$EABIARCH-
        CFLAGS=$OPTIMIZE_CFLAGS
        ADDITIONAL_CONFIGURE_FLAG="$ADDITIONAL_CONFIGURE_FLAG --enable-gpl --enable-libx264"
#CFLAGS=" -I$ARM_INC -fpic -DANDROID -fpic -mthumb-interwork -ffunction-sections -funwind-tables -fstack-protector -fno-short-enums -D__ARM_ARCH_5__ -D__ARM_ARCH_5T__ -D__ARM_ARCH_5E__ -D__ARM_ARCH_5TE__  -Wno-psabi -march=armv5te -mtune=xscale -msoft-float -mthumb -Os -fomit-frame-pointer -fno-strict-aliasing -finline-limit=64 -DANDROID  -Wa,--noexecstack -MMD -MP "
        export CPPFLAGS="$CFLAGS"
        export CFLAGS="$CFLAGS"
        export CXXFLAGS="$CFLAGS"
        export CXX="${CROSS_COMPILE}g++ --sysroot=$PLATFORM"
        export AS="${CROSS_COMPILE}gcc --sysroot=$PLATFORM"
        export CC="${CROSS_COMPILE}gcc --sysroot=$PLATFORM"
        export NM="${CROSS_COMPILE}nm"
        export STRIP="${CROSS_COMPILE}strip"
        export RANLIB="${CROSS_COMPILE}ranlib"
        export AR="${CROSS_COMPILE}ar"
        export LDFLAGS="-Wl,-rpath-link=$PLATFORM/usr/lib -L$PLATFORM/usr/lib -nostdlib -lc -lm -ldl -llog -lgcc"

        cd x264
        ./configure --prefix=$(pwd)/$PREFIX --disable-gpac --host=$ARCH-linux --enable-pic --enable-static $ADDITIONAL_CONFIGURE_FLAG || exit 1
        make clean || exit 1
        make STRIP= -j4 install || exit 1
        cd ..
    fi
}

function build_amr
{
    PLATFORM=$NDK/platforms/$PLATFORM_VERSION/arch-$ARCH/
    export PATH=${PATH}:$PREBUILT/bin/
    CROSS_COMPILE=$PREBUILT/bin/$EABIARCH-
    CFLAGS=$OPTIMIZE_CFLAGS
#CFLAGS=" -I$ARM_INC -fpic -DANDROID -fpic -mthumb-interwork -ffunction-sections -funwind-tables -fstack-protector -fno-short-enums -D__ARM_ARCH_5__ -D__ARM_ARCH_5T__ -D__ARM_ARCH_5E__ -D__ARM_ARCH_5TE__  -Wno-psabi -march=armv5te -mtune=xscale -msoft-float -mthumb -Os -fomit-frame-pointer -fno-strict-aliasing -finline-limit=64 -DANDROID  -Wa,--noexecstack -MMD -MP "
    export CPPFLAGS="$CFLAGS"
    export CFLAGS="$CFLAGS"
    export CXXFLAGS="$CFLAGS"
    export CXX="${CROSS_COMPILE}g++ --sysroot=$PLATFORM"
    export CC="${CROSS_COMPILE}gcc --sysroot=$PLATFORM"
    export NM="${CROSS_COMPILE}nm"
    export STRIP="${CROSS_COMPILE}strip"
    export RANLIB="${CROSS_COMPILE}ranlib"
    export AR="${CROSS_COMPILE}ar"
    export LDFLAGS="-Wl,-rpath-link=$PLATFORM/usr/lib -L$PLATFORM/usr/lib -nostdlib -lc -lm -ldl -llog"

    cd vo-amrwbenc
    ./configure \
        --prefix=$(pwd)/$PREFIX \
        --host=$ARCH-linux \
        --disable-dependency-tracking \
        --disable-shared \
        --enable-static \
        --with-pic \
        $ADDITIONAL_CONFIGURE_FLAG \
        || exit 1

    make clean || exit 1
    make -j4 install || exit 1
    cd ..
}

function build_aac
{
    PLATFORM=$NDK/platforms/$PLATFORM_VERSION/arch-$ARCH/
    export PATH=${PATH}:$PREBUILT/bin/
    CROSS_COMPILE=$PREBUILT/bin/$EABIARCH-
    CFLAGS=$OPTIMIZE_CFLAGS
#CFLAGS=" -I$ARM_INC -fpic -DANDROID -fpic -mthumb-interwork -ffunction-sections -funwind-tables -fstack-protector -fno-short-enums -D__ARM_ARCH_5__ -D__ARM_ARCH_5T__ -D__ARM_ARCH_5E__ -D__ARM_ARCH_5TE__  -Wno-psabi -march=armv5te -mtune=xscale -msoft-float -mthumb -Os -fomit-frame-pointer -fno-strict-aliasing -finline-limit=64 -DANDROID  -Wa,--noexecstack -MMD -MP "
    export CPPFLAGS="$CFLAGS"
    export CFLAGS="$CFLAGS"
    export CXXFLAGS="$CFLAGS"
    export CXX="${CROSS_COMPILE}g++ --sysroot=$PLATFORM"
    export CC="${CROSS_COMPILE}gcc --sysroot=$PLATFORM"
    export NM="${CROSS_COMPILE}nm"
    export STRIP="${CROSS_COMPILE}strip"
    export RANLIB="${CROSS_COMPILE}ranlib"
    export AR="${CROSS_COMPILE}ar"
    export LDFLAGS="-Wl,-rpath-link=$PLATFORM/usr/lib -L$PLATFORM/usr/lib -nostdlib -lc -lm -ldl -llog"

    if [ ! -z "$PREFER_FDK_AAC" ]; then
        echo "Using fdk-aac encoder for AAC"
        find vo-aacenc/ -name "*.o" -type f -delete
        ADDITIONAL_CONFIGURE_FLAG="$ADDITIONAL_CONFIGURE_FLAG --enable-libfdk_aac"
        cd fdk-aac
    else
        echo "Using vo-aacenc encoder for AAC"
        find fdk-aac/ -name "*.o" -type f -delete
        ADDITIONAL_CONFIGURE_FLAG="$ADDITIONAL_CONFIGURE_FLAG --enable-libvo-aacenc"
        cd vo-aacenc
    fi

    export PKG_CONFIG_LIBDIR=$(pwd)/$PREFIX/lib/pkgconfig/
    export PKG_CONFIG_PATH=$(pwd)/$PREFIX/lib/pkgconfig/
    ./configure \
        --prefix=$(pwd)/$PREFIX \
        --host=$ARCH-linux \
        --disable-dependency-tracking \
        --disable-shared \
        --enable-static \
        --with-pic \
        $ADDITIONAL_CONFIGURE_FLAG \
        || exit 1

    make clean || exit 1
    make -j4 install || exit 1
    cd ..
}
function build_png
{
    PLATFORM=$NDK/platforms/$PLATFORM_VERSION/arch-$ARCH/
    export PATH=${PATH}:$PREBUILT/bin/
    CROSS_COMPILE=$PREBUILT/bin/$EABIARCH-
    CFLAGS=$OPTIMIZE_CFLAGS
#CFLAGS=" -I$ARM_INC -fpic -DANDROID -fpic -mthumb-interwork -ffunction-sections -funwind-tables -fstack-protector -fno-short-enums -D__ARM_ARCH_5__ -D__ARM_ARCH_5T__ -D__ARM_ARCH_5E__ -D__ARM_ARCH_5TE__  -Wno-psabi -march=armv5te -mtune=xscale -msoft-float -mthumb -Os -fomit-frame-pointer -fno-strict-aliasing -finline-limit=64 -DANDROID  -Wa,--noexecstack -MMD -MP "
    export CPPFLAGS="$CFLAGS"
    export CFLAGS="$CFLAGS"
    export CXXFLAGS="$CFLAGS"
    export CXX="${CROSS_COMPILE}g++ --sysroot=$PLATFORM"
    export CC="${CROSS_COMPILE}gcc --sysroot=$PLATFORM"
    export NM="${CROSS_COMPILE}nm"
    export STRIP="${CROSS_COMPILE}strip"
    export RANLIB="${CROSS_COMPILE}ranlib"
    export AR="${CROSS_COMPILE}ar"
    export LDFLAGS="-Wl,-rpath-link=$PLATFORM/usr/lib -L$PLATFORM/usr/lib  -nostdlib -lc -lm -ldl -llog -lgcc"

    cd libpng
    ./configure \
        --prefix=$(pwd)/$PREFIX \
        --host=$ARCH-linux \
        --disable-dependency-tracking \
        --disable-shared \
        --enable-static \
        --with-pic \
        $ADDITIONAL_CONFIGURE_FLAG \
        || exit 1

    make clean || exit 1
    make -j4 install || exit 1
    cd ..
}
function build_freetype2
{
    PLATFORM=$NDK/platforms/$PLATFORM_VERSION/arch-$ARCH/
    export PATH=${PATH}:$PREBUILT/bin/
    CROSS_COMPILE=$PREBUILT/bin/$EABIARCH-
    CFLAGS=$OPTIMIZE_CFLAGS
#CFLAGS=" -I$ARM_INC -fpic -DANDROID -fpic -mthumb-interwork -ffunction-sections -funwind-tables -fstack-protector -fno-short-enums -D__ARM_ARCH_5__ -D__ARM_ARCH_5T__ -D__ARM_ARCH_5E__ -D__ARM_ARCH_5TE__  -Wno-psabi -march=armv5te -mtune=xscale -msoft-float -mthumb -Os -fomit-frame-pointer -fno-strict-aliasing -finline-limit=64 -DANDROID  -Wa,--noexecstack -MMD -MP "
    export CPPFLAGS="$CFLAGS"
    export CFLAGS="$CFLAGS"
    export CXXFLAGS="$CFLAGS"
    export CXX="${CROSS_COMPILE}g++ --sysroot=$PLATFORM"
    export CC="${CROSS_COMPILE}gcc --sysroot=$PLATFORM"
    export NM="${CROSS_COMPILE}nm"
    export STRIP="${CROSS_COMPILE}strip"
    export RANLIB="${CROSS_COMPILE}ranlib"
    export AR="${CROSS_COMPILE}ar"
    export LDFLAGS="-Wl,-rpath-link=$PLATFORM/usr/lib -L$PLATFORM/usr/lib  -nostdlib -lc -lm -ldl -llog"

    cd freetype2
    export PKG_CONFIG_LIBDIR=$(pwd)/$PREFIX/lib/pkgconfig/
    export PKG_CONFIG_PATH=$(pwd)/$PREFIX/lib/pkgconfig/
    ./configure \
        --prefix=$(pwd)/$PREFIX \
        --host=$ARCH-linux \
        --disable-dependency-tracking \
        --disable-shared \
        --enable-static \
        --with-pic \
        $ADDITIONAL_CONFIGURE_FLAG \
        || exit 1

    make clean || exit 1
    make -j4 || exit 1
    make -j4 install || exit 1
    cd ..
}
function build_ass
{
    PLATFORM=$NDK/platforms/$PLATFORM_VERSION/arch-$ARCH/
    export PATH=${PATH}:$PREBUILT/bin/
    CROSS_COMPILE=$PREBUILT/bin/$EABIARCH-
    CFLAGS="$OPTIMIZE_CFLAGS"
#CFLAGS=" -I$ARM_INC -fpic -DANDROID -fpic -mthumb-interwork -ffunction-sections -funwind-tables -fstack-protector -fno-short-enums -D__ARM_ARCH_5__ -D__ARM_ARCH_5T__ -D__ARM_ARCH_5E__ -D__ARM_ARCH_5TE__  -Wno-psabi -march=armv5te -mtune=xscale -msoft-float -mthumb -Os -fomit-frame-pointer -fno-strict-aliasing -finline-limit=64 -DANDROID  -Wa,--noexecstack -MMD -MP "
    export CPPFLAGS="$CFLAGS"
    export CFLAGS="$CFLAGS"
    export CXXFLAGS="$CFLAGS"
    export CXX="${CROSS_COMPILE}g++ --sysroot=$PLATFORM"
    export CC="${CROSS_COMPILE}gcc --sysroot=$PLATFORM"
    export NM="${CROSS_COMPILE}nm"
    export STRIP="${CROSS_COMPILE}strip"
    export RANLIB="${CROSS_COMPILE}ranlib"
    export AR="${CROSS_COMPILE}ar"
    export LDFLAGS="-Wl,-rpath-link=$PLATFORM/usr/lib -L$PLATFORM/usr/lib  -nostdlib -lc -lm -ldl -llog"

    cd libass
    export PKG_CONFIG_LIBDIR=$(pwd)/$PREFIX/lib/pkgconfig/
    export PKG_CONFIG_PATH=$(pwd)/$PREFIX/lib/pkgconfig/
    ./configure \
        --prefix=$(pwd)/$PREFIX \
        --host=$ARCH-linux \
        --disable-fontconfig \
        --disable-dependency-tracking \
        --disable-shared \
        --enable-static \
        --with-pic \
        $ADDITIONAL_CONFIGURE_FLAG \
        || exit 1

    make clean || exit 1
    make V=1 -j4 install || exit 1
    cd ..
}
function build_fribidi
{
    PLATFORM=$NDK/platforms/$PLATFORM_VERSION/arch-$ARCH/
    export PATH=${PATH}:$PREBUILT/bin/
    CROSS_COMPILE=$PREBUILT/bin/$EABIARCH-
    CFLAGS="$OPTIMIZE_CFLAGS -std=gnu99"
#CFLAGS=" -I$ARM_INC -fpic -DANDROID -fpic -mthumb-interwork -ffunction-sections -funwind-tables -fstack-protector -fno-short-enums -D__ARM_ARCH_5__ -D__ARM_ARCH_5T__ -D__ARM_ARCH_5E__ -D__ARM_ARCH_5TE__  -Wno-psabi -march=armv5te -mtune=xscale -msoft-float -mthumb -Os -fomit-frame-pointer -fno-strict-aliasing -finline-limit=64 -DANDROID  -Wa,--noexecstack -MMD -MP "
    export CPPFLAGS="$CFLAGS"
    export CFLAGS="$CFLAGS"
    export CXXFLAGS="$CFLAGS"
    export CXX="${CROSS_COMPILE}g++ --sysroot=$PLATFORM"
    export CC="${CROSS_COMPILE}gcc --sysroot=$PLATFORM"
    export NM="${CROSS_COMPILE}nm"
    export STRIP="${CROSS_COMPILE}strip"
    export RANLIB="${CROSS_COMPILE}ranlib"
    export AR="${CROSS_COMPILE}ar"
    export LDFLAGS="-Wl,-rpath-link=$PLATFORM/usr/lib -L$PLATFORM/usr/lib -nostdlib -lc -lm -ldl -llog"

    cd fribidi
    ./configure \
        --prefix=$(pwd)/$PREFIX \
        --host=$ARCH-linux \
        --disable-bin \
        --disable-dependency-tracking \
        --disable-shared \
        --enable-static \
        --with-pic \
        $ADDITIONAL_CONFIGURE_FLAG \
        || exit 1

    make clean || exit 1
    make -j4 install || exit 1
    cd ..
}
function build_ffmpeg
{
    PLATFORM=$NDK/platforms/$PLATFORM_VERSION/arch-$ARCH/
    CC=$PREBUILT/bin/$EABIARCH-gcc
    CROSS_PREFIX=$PREBUILT/bin/$EABIARCH-
    PKG_CONFIG=${CROSS_PREFIX}pkg-config
    if [ ! -f $PKG_CONFIG ];
    then
        cat > $PKG_CONFIG << EOF
#!/bin/bash
pkg-config \$*
EOF
        chmod u+x $PKG_CONFIG
    fi
    NM=$PREBUILT/bin/$EABIARCH-nm
    cd ffmpeg
    export PKG_CONFIG_LIBDIR=$(pwd)/$PREFIX/lib/pkgconfig/
    export PKG_CONFIG_PATH=$(pwd)/$PREFIX/lib/pkgconfig/
    ./configure --target-os=linux \
        --prefix=$PREFIX \
        --enable-cross-compile \
        --extra-libs="-lgcc" \
        --arch=$ARCH \
        --cc=$CC \
        --cross-prefix=$CROSS_PREFIX \
        --nm=$NM \
        --sysroot=$PLATFORM \
        --extra-cflags=" -O3 -fpic -DANDROID -DHAVE_SYS_UIO_H=1 -Dipv6mr_interface=ipv6mr_ifindex -fasm -Wno-psabi -fno-short-enums  -fno-strict-aliasing -finline-limit=300 $OPTIMIZE_CFLAGS " \
        --disable-shared \
        --enable-static \
        --enable-runtime-cpudetect \
        --extra-ldflags="-Wl,-rpath-link=$PLATFORM/usr/lib -L$PLATFORM/usr/lib  -nostdlib -lc -lm -ldl -llog -L$PREFIX/lib" \
        --extra-cflags="-I$PREFIX/include" \
        --enable-libvo-amrwbenc \
        --enable-bsfs \
        --enable-decoders \
        --enable-encoders \
        --enable-parsers \
        --enable-hwaccels \
        --enable-muxers \
        --enable-avformat \
        --enable-avcodec \
        --enable-avresample \
        --enable-zlib \
        --disable-doc \
        --disable-ffplay \
        --disable-ffmpeg \
        --disable-ffplay \
        --disable-ffprobe \
        --disable-ffserver \
        --disable-avfilter \
        --disable-avdevice \
        --enable-nonfree \
        --enable-version3 \
        --enable-memalign-hack \
        --enable-asm \
        $ADDITIONAL_CONFIGURE_FLAG \
        || exit 1
    make clean || exit 1
    make -j4 install || exit 1
    cd ..
}

function build_one {
    cd ffmpeg
    PLATFORM=$NDK/platforms/$PLATFORM_VERSION/arch-$ARCH/
    export LDFLAGS="-Wl,-rpath-link=$PLATFORM/usr/lib -L$PLATFORM/usr/lib -nostdlib -lc -lm -ldl -llog -lz"

    # Get all the object files inside FFMPEG
    FFMPEG_OBJS="libavutil/ libavcodec/ libavcodec/$ARCH/ libavformat/ libswresample/ libswscale/ libavfilter/ compat/ libavutil/$ARCH/"
    case $ARCH in
        arm)
            FFMPEG_OBJS=$FFMPEG_OBJS" libswresample/arm/ libavcodec/neon/"
        ;;
        x86)
            FFMPEG_OBJS=$FFMPEG_OBJS" libswresample/x86/ libswscale/x86/ libavfilter/x86/"
        ;;
        # Default works with mips
    esac

    # Check each FFMPEG object path if they exist before adding them to the list
    OBJS=
    for path in $FFMPEG_OBJS; do
        objs_path=$path"*.o"
        if [ `ls -1 $objs_path 2>/dev/null | wc -l` -gt "0" ]; then
            OBJS=$OBJS" "$objs_path
        fi
    done

    # Finally package into shared library
    rm -f libavcodec/inverse.o ../vo-aacenc/common/cmnMemory.o
    $CC -o $OUT_LIBRARY -shared -nostdlib -Wl,-z,noexecstack -Bsymbolic $LDFLAGS $EXTRA_LDFLAGS $OBJS \
          $(find ../ -name "*.o" -not -path "../ffmpeg/*" | tr '\n' ' ') \
          -zmuldefs $PREBUILT/lib/gcc/$EABIARCH/$TOOLCHAIN_VER/libgcc.a
    $PREBUILT/bin/$EABIARCH-strip --strip-unneeded $OUT_LIBRARY
    cd ..
}
function build_subtitles
{
    if [ ! -z "$BUILD_WITH_SUBS" ]; then
        build_fribidi
        build_png
        build_freetype2
        build_ass
        ADDITIONAL_CONFIGURE_FLAG=$ADDITIONAL_CONFIGURE_FLAG" --enable-libass"
    else
        # Delete object files so they don't get included when building shared library
        find fribidi/ -name "*.o" -type f -delete
        find libpng/ -name "*.o" -type f -delete
        find freetype2/ -name "*.o" -type f -delete
        find libass/ -name "*.o" -type f -delete
    fi
}

#arm v5
if [[ " ${archs[*]} " == *" armeabi "* ]] || [ "$build_all" = true ]; then
EABIARCH=arm-linux-androideabi
ARCH=arm
CPU=armv5
OPTIMIZE_CFLAGS="-marm -march=$CPU"
PREFIX=../../VPlayer_library/jni/ffmpeg-build/armeabi
OUT_LIBRARY=$PREFIX/libffmpeg.so
ADDITIONAL_CONFIGURE_FLAG=
SONAME=libffmpeg.so
PREBUILT=$NDK/toolchains/arm-linux-androideabi-$TOOLCHAIN_VER/prebuilt/$OS-x86
if [ ! -d "$PREBUILT" ]; then PREBUILT="$PREBUILT"_64; fi
# If you want x264, compile armv6
find x264/ -name "*.o" -type f -delete
build_amr
build_aac
build_subtitles
build_ffmpeg
build_one
fi

#x86
if [[ " ${archs[*]} " == *" x86 "* ]] || [ "$build_all" = true ]; then
EABIARCH=i686-linux-android
ARCH=x86
OPTIMIZE_CFLAGS="-m32"
PREFIX=../../VPlayer_library/jni/ffmpeg-build/x86
OUT_LIBRARY=$PREFIX/libffmpeg.so
ADDITIONAL_CONFIGURE_FLAG=--disable-asm
SONAME=libffmpeg.so
PREBUILT=$NDK/toolchains/x86-$TOOLCHAIN_VER/prebuilt/$OS-x86
if [ ! -d "$PREBUILT" ]; then PREBUILT="$PREBUILT"_64; fi
build_x264
build_amr
build_aac
build_subtitles
build_ffmpeg
build_one
fi

#mips
if [[ " ${archs[*]} " == *" mips "* ]] || [ "$build_all" = true ]; then
EABIARCH=mipsel-linux-android
ARCH=mips
OPTIMIZE_CFLAGS="-EL -march=mips32 -mips32 -mhard-float"
PREFIX=../../VPlayer_library/jni/ffmpeg-build/mips
OUT_LIBRARY=$PREFIX/libffmpeg.so
ADDITIONAL_CONFIGURE_FLAG="--disable-mipsdspr1 --disable-mipsdspr2"
SONAME=libffmpeg.so
PREBUILT=$NDK/toolchains/mipsel-linux-android-$TOOLCHAIN_VER/prebuilt/$OS-x86
if [ ! -d "$PREBUILT" ]; then PREBUILT="$PREBUILT"_64; fi
build_x264
build_amr
build_aac
build_subtitles
build_ffmpeg
build_one
fi

if [[ " ${archs[*]} " == *" armeabi-v7a "* ]] || [ "$build_all" = true ]; then
#arm v7vfpv3
EABIARCH=arm-linux-androideabi
ARCH=arm
CPU=armv7-a
OPTIMIZE_CFLAGS="-mfloat-abi=softfp -mfpu=vfpv3-d16 -marm -march=$CPU "
PREFIX=../../VPlayer_library/jni/ffmpeg-build/armeabi-v7a
OUT_LIBRARY=$PREFIX/libffmpeg.so
ADDITIONAL_CONFIGURE_FLAG=
SONAME=libffmpeg.so
EXTRA_LDFLAGS="-Wl,--fix-cortex-a8"
PREBUILT=$NDK/toolchains/arm-linux-androideabi-$TOOLCHAIN_VER/prebuilt/$OS-x86
if [ ! -d "$PREBUILT" ]; then PREBUILT="$PREBUILT"_64; fi
build_x264
build_amr
build_aac
build_subtitles
build_ffmpeg
build_one

#arm v7 + neon (neon also include vfpv3-32)
EABIARCH=arm-linux-androideabi
ARCH=arm
CPU=armv7-a
OPTIMIZE_CFLAGS="-mfloat-abi=softfp -mfpu=neon -marm -march=$CPU -mtune=cortex-a8 -mthumb -D__thumb__ "
PREFIX=../../VPlayer_library/jni/ffmpeg-build/armeabi-v7a-neon
OUT_LIBRARY=../../VPlayer_library/jni/ffmpeg-build/armeabi-v7a/libffmpeg-neon.so
ADDITIONAL_CONFIGURE_FLAG=--enable-neon
SONAME=libffmpeg-neon.so
EXTRA_LDFLAGS="-Wl,--fix-cortex-a8"
PREBUILT=$NDK/toolchains/arm-linux-androideabi-$TOOLCHAIN_VER/prebuilt/$OS-x86
if [ ! -d "$PREBUILT" ]; then PREBUILT="$PREBUILT"_64; fi
build_x264
build_amr
build_aac
build_subtitles
build_ffmpeg
build_one
fi
