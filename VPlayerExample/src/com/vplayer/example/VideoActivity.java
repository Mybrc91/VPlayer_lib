package com.vplayer.example;

import java.io.File;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.PixelFormat;
import android.graphics.Point;
import android.os.Bundle;
import android.view.Display;
import android.view.Gravity;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.Window;
import android.widget.FrameLayout;
import android.widget.Toast;

import com.vplayer.MediaStreamInfo;
import com.vplayer.VPlayerListener;
import com.vplayer.VPlayerView;
import com.vplayer.exception.NotPlayingException;
import com.vplayer.exception.VPlayerException;

public class VideoActivity extends Activity {
    public static final String VideoPath = "video_path_key";

    public static final String SystemFontPath = "/system/fonts/";
    public static final String[] PossibleSubtitleFonts = {
        "Roboto-Regular.ttf", "Roboto-Light.ttf", "AndroidClock.ttf", "DroidSans.ttf"
    };

    private VPlayerView mPlayerView;
    private AlertDialog mDialog;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        this.getWindow().requestFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFormat(PixelFormat.RGBA_8888);
        super.onCreate(savedInstanceState);
        findViewById(android.R.id.content).setBackgroundColor(Color.BLACK);

        Intent in = getIntent();
        if (in != null) {
            String path = in.getStringExtra(VideoPath);
            if (path != null && new File(path).exists()) {
                attachPlayer(path);
                return;
            }
        }

        // No video was passed when starting this activity
        alert(null, "There was no video found, going back.");
    }

    private void attachPlayer(String path) {
        mPlayerView = new VPlayerView(this);
        mPlayerView.setVideoListener(new VPlayerListener() {
            @Override
            public void onMediaSourceLoaded(VPlayerException err, MediaStreamInfo[] streams) {
                if (err != null) {
                    alert("Decode Error", "Unable to read the video!");
                } else {
                    // Get the display dimensions
                    Display display = getWindowManager().getDefaultDisplay();
                    Point size = new Point();
                    display.getSize(size);

                    // Fill the screen with the video with correct aspect ratio
                    FrameLayout.LayoutParams params = (FrameLayout.LayoutParams) mPlayerView.getLayoutParams();
                    params.height = size.y;
                    params.width = (int) (size.y * mPlayerView.getVideoWidth() * 1.0 / mPlayerView.getVideoHeight());
                    params.gravity = Gravity.CENTER;
                    mPlayerView.setLayoutParams(params);

                    // Play the video
                    mPlayerView.play();
                }
            }
            @Override
            public void onMediaPause(NotPlayingException err) {
                Toast.makeText(VideoActivity.this, "Pause", Toast.LENGTH_SHORT).show();
            }
            @Override
            public void onMediaResume(NotPlayingException result) {
                Toast.makeText(VideoActivity.this, "Play", Toast.LENGTH_SHORT).show();
            }
            @Override
            public void onMediaUpdateTime(long mCurrentTimeUs,
                    long mVideoDurationUs, boolean isFinished) {
                if (isFinished) {
                    Toast.makeText(VideoActivity.this, "Video is finished", Toast.LENGTH_SHORT).show();
                }
            }
        });
        setContentView(mPlayerView);

        // Toggle pause when you click the video
        mPlayerView.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                if (mPlayerView.isPlaying()) {
                    mPlayerView.pause();
                } else {
                    mPlayerView.play();
                }
            }
        });

        mPlayerView.setWindowFullscreen();

        // Choose existing font
        String fontPath = null;
        for (String font : PossibleSubtitleFonts) {
            File file = new File(SystemFontPath + font);
            if (file.exists() && file.canRead()) {
                fontPath = file.getAbsolutePath();
                break;
            }
        }

        // Set the video path
        mPlayerView.setDataSource(path, fontPath);
    }

    private void alert(String title, String message) {
        if (mDialog == null) {
            mDialog = new AlertDialog.Builder(this)
                .setNeutralButton(android.R.string.ok, new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        finish();
                    }
                }).create();
        }
        mDialog.setMessage(message);
        mDialog.setTitle(title);
        mDialog.show();
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
