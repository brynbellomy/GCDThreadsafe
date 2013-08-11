#!/bin/sh

#set -e

WORKSPACE_FILENAME=./GCDThreadsafe.xcworkspace
SCHEME_NAME=GCDThreadsafe

echo "===========> Doing 'build test' command (no -sdk flag)"
xctool -workspace "$WORKSPACE_FILENAME" -scheme "$SCHEME_NAME" build test

echo "===========> Doing 'run-tests' command (no -sdk flag)"
xctool -workspace "$WORKSPACE_FILENAME" -scheme "$SCHEME_NAME" run-tests

#xctool -workspace ./GCDThreadsafe.xcworkspace -scheme GCDThreadsafe -sdk  build test

