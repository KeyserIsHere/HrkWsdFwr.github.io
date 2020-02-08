#!/bin/bash

usage() { echo "Usage: $0 [-h] [-s] [-p]" 1>&2; exit 1; }

while getopts "hsp" opt; do
    case "${opt}" in
        s)
            shallow=1
            ;;
        p)
            preserve=1
            ;;
        h|*)
            usage
            ;;
    esac
done

build=${BUILD_DIR:-build}

if [ -z "${shallow}" ]; then
    if [ -z "${preserve}" ]; then
        git submodule update
    fi

    parent=$(echo $build | sed s/[^\/]*/../g)

    cd deps/Blob2D
    sh setup.sh $@
    cd "../../"
fi

cd ../../
rm -rf "$build"
ruby deps/Blob2D/deps/CommonGameKit/build.rb --executable \
--define=CC_QUICK_COMPILE=1 \
--framework="deps/Blob2D/$build/Blob2D" \
--dylib="deps/Blob2D/$build/Blob2D/CommonGameKit/CommonGameKit.dylib","deps/Blob2D/$build/Blob2D/CommonGameKit" \
--header=deps/Blob2D/deps/CommonGameKit/deps/CommonC \
--header=deps/Blob2D/deps/CommonGameKit/deps/stdatomic \
--header=deps/Blob2D/deps/CommonGameKit/deps/threads \
--header=deps/Blob2D/deps/CommonGameKit/deps/tinycthread/source
cd "$build"
ninja
