/*
 * VPlayerView.java
 * Copyright (c) 2014 Matthew Ng
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

package com.vplayer;

import android.app.Activity;
import android.util.AttributeSet;
import android.view.WindowManager;

public class VPlayerView extends VPlayerSurfaceView {
    private final VPlayerController mPlayer;
    private final Activity mAct;
    private boolean mIsPlaying;

    public VPlayerView(Activity activity) {
        this(activity, null);
    }

    public VPlayerView(Activity activity, AttributeSet attrs) {
        this(activity, attrs, 0);
    }

    public VPlayerView(Activity activity, AttributeSet attrs, int defStyle) {
        super(activity, attrs, defStyle);
        mAct = activity;
        mPlayer = new VPlayerController(this, activity);
        mIsPlaying = false;
    }

    public void setWindowFullscreen() {
        mAct.getWindow().addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);
        mAct.getWindow().clearFlags(WindowManager.LayoutParams.FLAG_FORCE_NOT_FULLSCREEN);
        mAct.getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
    }

    public void clearWindowFullscreen() {
        mAct.getWindow().clearFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);
        mAct.getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
    }

    public void setVideoPath(String path) {
        mPlayer.setDataSource(path);
    }

    public void setVideoListener(VPlayerListener listener) {
        mPlayer.setMpegListener(listener);
    }

    public void onPause() {
        if (mIsPlaying) {
            pause();
        }
    }

    public void onResume() {
        if (!mIsPlaying) {
            play();
        }
    }

    public void onDestroy() {
        mPlayer.stop();
    }

    public void pause() {
        mIsPlaying = false;
        mPlayer.pause();
    }

    public void seek(long positionUs) {
        mPlayer.seek(positionUs);
    }

    public void play() {
        mIsPlaying = true;
        mPlayer.resume();
    }

    public void stop() {
        pause();
        mPlayer.seek(0);
    }

    public int getVideoWidth() {
        return mPlayer.getVideoWidth();
    }

    public int getVideoHeight() {
        return mPlayer.getVideoHeight();
    }

    public boolean isPlaying() {
        return mIsPlaying;
    }

}
