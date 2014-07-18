#!/bin/bash

# Do it twice incase some repos are not cloned!
# You only need ffmpeg repo if you are not building it, but we have to update all submodules
git submodule update --init --recursive
git submodule update --init --recursive

# Copy all the header files into ffmpeg folder under the project
SRC_FFMPEG=../../ffmpeg_build/ffmpeg
DST_FFMPEG=ffmpeg
mkdir -p $DST_FFMPEG
(cd $SRC_FFMPEG && find . -name '*.h' -print | tar --create --files-from -) | (cd $DST_FFMPEG && tar xvfp -)

# You need SVN!
svn checkout http://libyuv.googlecode.com/svn/trunk/ libyuv
