# VPlayer Library
This project provides the easiest way to include FFmpeg into any Android project with almost no NDK building and tweaking.
Of course if you want to customize FFmpeg, you will have to build the project from scratch.

Forked from [appunite/AndroidFFmpeg](https://github.com/appunite/AndroidFFmpeg), this project has a few enhancements since
they stopped updating the repository around April 2013. I have added some more functionality and a new simple project for
developers to get started with.

Read the wikis for this work. Even if you are a beginner to NDK, this project should be comprehensable enough to include 
VPlayer into your project. I provide prebuilt binaries for the project.

## Changes/Fixes from AndroidFFmpeg

- Allows video application pausing and resuming when user suspends app (going home or another app)
- Fixes crashing issue when using the same video player for multiple videos (with or without subs)
- Fixes video startup crashes after returning from a video
- Added hardware acceleration to YUV420 videos
- Added a single build file to compile all dependencies without any need of commandline
- Changed the Java library to easily integrate a video into a project
- Added looping functionality

## Sample integration

This is a very simple example that plays a video after starting the activity.
You can view more integration tutorials [here](https://github.com/matthewn4444/VPlayer_lib/wiki/Integration-Tutorial).

    public class VideoActivity extends Activity {
        private VPlayerView mPlayerView;

        @Override
        protected void onCreate(Bundle savedInstanceState) {
            super.onCreate(savedInstanceState);

            // Attach the player
            mPlayerView = new VPlayerView(this);
            setContentView(mPlayerView);

            // Set the content and play the video
            mPlayerView.setDataSource(path);
            mPlayerView.play();
        }

        @Override
        protected void onPause() {
            super.onPause();
            mPlayerView.onPause();
        }

        @Override
        protected void onResume() {
            super.onResume();
            mPlayerView.onResume();
        }

        @Override
        public void finish() {
            super.finish();
            mPlayerView.finish();
        }
    }

## Cloning and Building

You can clone the project here:

`` git clone git@github.com:matthewn4444/VPlayer_lib.git``

For building the project, please refer [here](https://github.com/matthewn4444/VPlayer_lib/wiki/Compiling-VPlayer).

## License
Copyright (C) 2014 Matthew Ng
Licensed under the Apache License, Verision 2.0

AndroidFFmpeg, FFmpeg, libvo-aacenc, vo-amrwbenc, libyuv and others libraries projects are distributed on theirs own license.

## Patent disclaimer
We do not grant of patent rights.
Some codecs use patented techniques and before use those parts of library you have to buy thrid-party patents.

## Credits
This library was modified by Matthew Ng from the original author Jacek Marchwicki 
from Appunite.com and other libraries he used. Also thanks to his issues page that
fixed a bunch of issues.
