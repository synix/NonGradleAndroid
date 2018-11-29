#!/bin/bash

set -e

BUILD_TOOLS="/Users/synix/Library/Android/sdk/build-tools/28.0.3" 

AAPT2="$BUILD_TOOLS/aapt2"
D8="$BUILD_TOOLS/d8"
ZIPALIGN="$BUILD_TOOLS/zipalign"
APKSIGNER="$BUILD_TOOLS/apksigner"

PLATFORM="/Users/synix/Library/Android/sdk/platforms/android-28/android.jar"

echo "Cleaning..."
rm -rf classes/
rm -rf compiled/
rm -rf build/

echo "Compiling resources..."
mkdir -p compiled
$AAPT2 compile res/values/strings.xml res/layout/activity_main.xml -o compiled/


echo "Linking resources & Generating R.java.."
mkdir -p build
$AAPT2 link -o build/unsigned_app.apk -I $PLATFORM \
    -R compiled/*.flat \
    --manifest AndroidManifest.xml \
    --java src/ \
    -v

echo "Compiling Java source code..."
mkdir -p classes
javac -d classes -classpath src -bootclasspath $PLATFORM -source 1.8 -target 1.8 src/io/github/synix/helloworld/MainActivity.java
javac -d classes -classpath src -bootclasspath $PLATFORM -source 1.8 -target 1.8 src/io/github/synix/helloworld/R.java

echo "Translating to Dalvik bytecode..."
$D8 classes/io/github/synix/helloworld/*.class --lib $PLATFORM --output build/

echo "Packaging APK..."
# Maybe have better solution than using zip 
zip -uj build/unsigned_app.apk build/classes.dex

echo "Aligning APK..."
$ZIPALIGN -f 4 build/unsigned_app.apk build/app.apk

echo "Signing APK..."
$APKSIGNER sign --ks release.keystore build/app.apk


if [ "$1" == "launch" ]; then
	echo "Launching..."
	adb install -r build/app.apk
	adb shell am start -n io.github.synix.helloworld/.MainActivity
fi