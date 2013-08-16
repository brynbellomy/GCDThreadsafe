#!/bin/sh
set -e

xctool -workspace GCDThreadsafe.xcworkspace -scheme GCDThreadsafe -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO build-tests run-tests


