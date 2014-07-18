#!/bin/bash

# Change location to the NDK8 folder
if [ "$NDK" = "" ]; then
    export NDK=~/Projects/ndk-8
fi

GIT_SSL_NO_VERIFY=true

function addAutomakeOpts() {
    if !(grep -Rq "AUTOMAKE_OPTIONS" Makefile.am)
    then
        sed -i '1iAUTOMAKE_OPTIONS=subdir-objects' Makefile.am
    fi
}

cd ..
git submodule update --init --recursive
cd ffmpeg_build

# Because it is svn...
svn checkout http://libyuv.googlecode.com/svn/trunk/ ../VPlayer_library/jni/libyuv

# configure the environment
cd freetype2
sh ./autogen.sh
cd ..

# fribidi
cd fribidi
autoreconf -ivf
cd ..

# libass
cd libass
autoreconf -ivf
cd ..

# aacenc environment
cd vo-aacenc
addAutomakeOpts
autoreconf -ivf
cd ..

# vo-amrwbenc environment
cd vo-amrwbenc
addAutomakeOpts
autoreconf -ivf
cd ..

# Start the build!
source build_android.sh

