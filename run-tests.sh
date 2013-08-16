#!/bin/sh

WORKSPACE_FILENAME=GCDThreadsafe.xcworkspace
SCHEME_NAME=GCDThreadsafe

xctool -workspace "$WORKSPACE_FILENAME" -scheme "$SCHEME_NAME" -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO build-tests run-tests


