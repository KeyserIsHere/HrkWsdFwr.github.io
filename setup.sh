git submodule update

cd deps/Blob2D
sh setup.sh

build=${BUILD_DIR:-build}

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
