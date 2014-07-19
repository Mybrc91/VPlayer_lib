package com.vplayer;

import com.vplayer.exception.NotPlayingException;
import com.vplayer.exception.VPlayerException;

public interface VPlayerListener {
    void onMediaSourceLoaded(VPlayerException err, MediaStreamInfo[] streams);
    void onMediaResume(NotPlayingException result);
    void onMediaPause(NotPlayingException err);
    void onMediaStop();
    void onMediaUpdateTime(long mCurrentTimeUs, long mVideoDurationUs, boolean isFinished);
    void onMediaSeeked(NotPlayingException result);
}