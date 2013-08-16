#!/bin/sh
set -e

echo "===========> Doing 'clean' command"
xctool -sdk iphonesimulator clean

echo "===========> Doing 'build' command"
xctool -sdk iphonesimulator build

echo "===========> Doing 'build-tests' command"
xctool build-tests

echo "===========> Doing 'run-tests' command"
xctool run-tests -test-sdk iphonesimulator -freshInstall -freshSimulator


