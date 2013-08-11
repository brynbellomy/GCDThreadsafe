#!/bin/sh
set -e

xctool -workspace GCDThreadsafe -scheme GCDThreadsafe build test

