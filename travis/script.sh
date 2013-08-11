#!/bin/sh
set -e

WORKSPACE_FILENAME=./GCDThreadsafe.xcworkspace
SCHEME_NAME=GCDThreadsafe

xctool -workspace "$WORKSPACE_FILENAME" -scheme "$SCHEME_NAME" -sdk iphonesimulator build test

#xctool -workspace ./GCDThreadsafe.xcworkspace -scheme GCDThreadsafe -sdk  build test

