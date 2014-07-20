/*
 * VPlayerSurfaceView.java
 * Copyright (c) 2012 Jacek Marchwicki, modified by Matthew Ng
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

import android.content.Context;
import android.graphics.PixelFormat;
import android.util.AttributeSet;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;

import com.vplayer.VPlayerController.VPlayerDisplay;

class VPlayerSurfaceView extends SurfaceView implements VPlayerDisplay,
        SurfaceHolder.Callback {

    public static enum ScaleType {
        CENTER_CROP, CENTER_INSIDE, FIT_XY
    }

    private VPlayerController mMpegPlayer = null;
    private boolean mCreated = false;
    private boolean mAboutToFinish = false;

    public VPlayerSurfaceView(Context context) {
        this(context, null, 0);
    }

    public VPlayerSurfaceView(Context context, AttributeSet attrs) {
        this(context, attrs, 0);
    }

    public VPlayerSurfaceView(Context context, AttributeSet attrs, int defStyle) {
        super(context, attrs, defStyle);

        SurfaceHolder holder = getHolder();
        holder.setFormat(PixelFormat.RGBA_8888);
        holder.addCallback(this);
    }

    @Override
    public void setMpegPlayer(VPlayerController vPlayerController) {
        if (mMpegPlayer != null) {
            throw new RuntimeException(
                    "setMpegPlayer could not be called twice");
        }

        this.mMpegPlayer = vPlayerController;
    }

    @Override
    public void surfaceChanged(SurfaceHolder holder, int format, int width,
            int height) {

    }

    @Override
    public void surfaceCreated(SurfaceHolder holder) {
        if (mCreated  == true) {
            surfaceDestroyed(holder);
        }

        Surface surface = holder.getSurface();
        mMpegPlayer.render(surface);
        mCreated = true;
    }

    @Override
    public void surfaceDestroyed(SurfaceHolder holder) {
        if (mAboutToFinish) {
            mMpegPlayer.renderFrameStop();
        } else {
            // This will cause a surface error in logcat when going home but will not crash, ignore it
            //     queueBuffer: error queuing buffer to SurfaceTexture, -19
            //     queueBuffer (handle=0x2a5e89f8) failed (No such device)
            mMpegPlayer.renderFramePause();
        }
        mCreated = false;
    }

    // You must use this from an activity finish() or else the video's sound will end awkwardly
    public void finish() {
        mAboutToFinish = true;
    }

}
