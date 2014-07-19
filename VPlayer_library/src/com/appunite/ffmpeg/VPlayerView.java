package com.appunite.ffmpeg;

import android.app.Activity;
import android.util.AttributeSet;
import android.view.WindowManager;

public class VPlayerView extends FFmpegSurfaceView {
    private final FFmpegPlayer mPlayer;
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
        mPlayer = new FFmpegPlayer(this, activity);
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

    public void setVideoListener(FFmpegListener listener) {
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
