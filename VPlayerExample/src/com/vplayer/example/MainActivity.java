package com.vplayer.example;

import java.io.File;
import java.io.FileFilter;
import java.io.FileNotFoundException;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.os.Bundle;
import android.os.Environment;
import android.view.View;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.ListView;
import android.widget.Toast;

public class MainActivity extends Activity implements OnItemClickListener {

    public static String[] VIDEO_FORMATS = {
        ".avi", ".mpeg", ".mpg", ".m1v", ".m2v", ".mkv", ".mjpeg", ".mjpg", ".webm", ".mp4", ".mov", ".m4v", ".mp4v", ".3gp", ".wmv"
    };

    private FileSystemAdapter mAdapter;
    private boolean mShowedToastBeforeBackExit = false;

    private final FileFilter mVideoFilter = new FileFilter() {
        @Override
        public boolean accept(File pathname) {
            return pathname.isDirectory() || pathname.isFile() && isVideoFile(pathname);
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        final File storage = Environment.getExternalStorageDirectory();
        try {
            mAdapter = new FileSystemAdapter(this, storage, true);
            mAdapter.addLowerBoundFile(storage);
            mAdapter.setFileFilter(mVideoFilter);
        } catch (FileNotFoundException e) {
            e.printStackTrace();
            Toast.makeText(this, "Failed to find external storage!", Toast.LENGTH_LONG).show();
            return;
        }

        final ListView listView = new ListView(this);
        listView.setBackgroundColor(Color.WHITE);
        listView.setAdapter(mAdapter);
        listView.setOnItemClickListener(this);
        setContentView(listView);
    }

    private boolean isVideoFile(File file) {
        String name = file.getName();
        for (int i = 0; i < VIDEO_FORMATS.length; i++) {
            if (name.endsWith(VIDEO_FORMATS[i])) {
                return true;
            }
        }
        return false;
    }

    @Override
    public void onItemClick(AdapterView<?> parent, View view, int position,
            long id) {
        File selectedFile = mAdapter.getFile(position);

        // Detect back button press
        if (selectedFile == null) {
            mAdapter.moveUp();
            return;
        }

        // Check permissions of this folder
        if (!selectedFile.canRead()) {
            Toast.makeText(this, "Unable to open this folder due to lack of permissions.", Toast.LENGTH_SHORT).show();
            return;
        }

        if (selectedFile.isDirectory()) {
            mAdapter.setChildAsCurrent(position);
        } else {    // is a file
            Intent in = new Intent(this, VideoActivity.class);
            in.putExtra(VideoActivity.VideoPath, selectedFile.getPath());
            startActivity(in);
        }
    }

    @Override
    public void onBackPressed() {
        if (mAdapter != null) {
            // Back button will exit
            if (mAdapter.isDirectoryAtLowerBound()) {
                if (mShowedToastBeforeBackExit) {
                    super.onBackPressed();
                } else {
                    mShowedToastBeforeBackExit = true;
                    Toast.makeText(this, "Press back again to exit", Toast.LENGTH_SHORT).show();
                }
            } else {
                mShowedToastBeforeBackExit = false;
                mAdapter.showBackListItem(true);
                mAdapter.moveUp();
            }
        }
    }
}
