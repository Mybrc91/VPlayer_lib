#!/bin/bash

git submodule update --init --recursive

svn checkout http://libyuv.googlecode.com/svn/trunk/ libyuv