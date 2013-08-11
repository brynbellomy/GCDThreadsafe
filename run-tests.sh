#!/bin/sh

WORKSPACE_FILENAME=./GCDThreadsafe.xcworkspace
SCHEME_NAME=GCDThreadsafe

xctool run-tests -workspace "$WORKSPACE_FILENAME" -scheme "$SCHEME_NAME" -sdk iphonesimulator

