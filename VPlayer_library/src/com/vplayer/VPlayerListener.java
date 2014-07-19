package com.vplayer;

import com.vplayer.exception.NotPlayingException;
import com.vplayer.exception.VPlayerException;

public abstract class VPlayerListener {
    public void onMediaSourceLoaded(VPlayerException err, MediaStreamInfo[] streams) {}
    public void onMediaResume(NotPlayingException result) {}
    public void onMediaPause(NotPlayingException err) {}
    public void onMediaStop() {}
    public void onMediaUpdateTime(long mCurrentTimeUs, long mVideoDurationUs, boolean isFinished) {}
    public void onMediaSeeked(NotPlayingException result) {}
}
