This page describes how to compile FFmpeg using NDK for Android. This is a more advanced challenge and is not for beginners that are learning NDK.

## Prerequisites

### Tools

**Compiles only on Mac and Linux** (Windows would need work and there is no steps given here).

You need the following tools:

- autoconf
- autoconf-archive
- automake
- pkg-config
- git
- svn

For mac: you have to install xcode and command tools from xcode preferences (tool brew from homebrew project)
For Debian/Ubuntu: you can use apt-get

**Download [Eclipse](https://developer.android.com/sdk/index.html)** and setup the environment for Android (or [Android Studio](https://developer.android.com/sdk/installing/studio.html), or use Ant if you want). Note that this wiki only mentions about Eclipse, the other stuff you have to learn yourself.

**Download NDK-8** because NDK9+ will not compile FFmpeg out of the box (aka you need to do more work which I am not describing). Put it somewhere easy to access (like in your home directory); **make sure no spaces in the path!**

- Linux: [https://dl.google.com/android/ndk/android-ndk-r8e-linux-x86.tar.bz2](https://dl.google.com/android/ndk/android-ndk-r8e-linux-x86.tar.bz2)
- Mac: [https://dl.google.com/android/ndk/android-ndk-r8e-darwin-x86.tar.bz2](https://dl.google.com/android/ndk/android-ndk-r8e-darwin-x86.tar.bz2)

### Cloning the project

Clone the project:

``git clone git@github.com:matthewn4444/VPlayer_lib.git``

## Building Source

Assuming that you did everything in the prerequisites section, this should be smooth

### Building FFmpeg

_*Note: If you want to speed up the build process, limit the architectures and/or lessen the codecs.*_

1. Set the path to NDK: ``export NDK=~/<path to NDK>/NDK`` where it should be v8

2. Go into the folder **<root>/ffmpeg_build** and run **config_and_build.sh** once. 
   - If the build fails, you might want to run this again. 
   - If build is succeeds and then if you want to build again, you only need to run **build_android.sh** (you do not need to configure again)

3. The output of the files are in **<root>/VPlayer_library/jni/ffmpeg-build/<arch>/libffmpeg.so**

### Customizing FFmpeg

Edit the file **<root>/ffmpeg_build/build_android.sh**

#### Customize Architectures

At the bottom, there are code blocks for arm v5, x86, mips, arm v7vfpv3 and arm v7 + neon. Remember with this file, it builds each at over 30mb each, limiting which architecture to build will reduce build time.

You can comment an entire block to ignore the build for a certain architecture.

#### Customize Codecs

Starting from line 244 lists a bunch of configurations for FFmpeg. After **--disable-everything** you can disable enable certain codecs. [Here](http://ffmpeg.mplayerhq.hu/general.html) is some more information.

#### x264

Since I cannot get this to work, you can try building it yourself. The prebuilt libraries do not include these.

## Extra Stuff

This stuff is not needed for building FFmpeg, just extra information.

### What _*config_and_build.sh*_ does

On AndroidFFmpeg's readme, he gives some instructions of how to customize before building. The problem is that some of his instructions are out of date and would not work without extra Googling. This script does all of that so it makes this process easier. This is what it does:

1. ``git submodule update --init --recursive``
   
   Recursively updates all the submodules and downloads the other libraries (such as libass and FFmpeg)

2. ``svn checkout http://libyuv.googlecode.com/svn/trunk/ ../VPlayer_library/jni/libyuv``

   libyuv is the only library submitted via SVN and it checkouts the project to the jni file of the library

3. ``sh ./autogen.sh`` & ``autoreconf -ivf``

   These two are used to configure the environments for freetype2, fribidi, libass, vo-aacenc and vo-amrwbenc

4. ``addAutomakeOpts``

   Adds ``1iAUTOMAKE_OPTIONS=subdir-objects`` to the Makefile.am files inside vo-aacenc and vo-amrwbenc because it needs them to configure successfully.

5. ``source build_android.sh``
   Starts the compilation of FFmpeg.

