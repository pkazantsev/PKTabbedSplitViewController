#!/usr/bin/env zsh

set -euo pipefail

OUTPUT_PATH="build/PKTabbedSplitViewController"

rm -rf "$OUTPUT_PATH"
mkdir -p "$OUTPUT_PATH"

OUTPUT_PATH=$(realpath "$OUTPUT_PATH")

echo "Building for simulator. For details, see $OUTPUT_PATH/build_sim.log"
xcodebuild clean archive \
	-scheme PKTabbedSplitViewController \
	-configuration Release \
	-archivePath $OUTPUT_PATH/ios_sim \
	-destination "generic/platform=iOS Simulator" \
	SKIP_INSTALL=NO \
	ONLY_ACTIVE_ARCH=NO \
	BUILD_LIBRARY_FOR_DISTRIBUTION=YES > $OUTPUT_PATH/build_sim.log
echo "Success!"

echo "Building for device. For details, see $OUTPUT_PATH/build_dev.log"
xcodebuild clean archive \
	-scheme PKTabbedSplitViewController \
	-configuration Release \
	-archivePath $OUTPUT_PATH/ios_dev \
	-destination "generic/platform=iOS" \
	SKIP_INSTALL=NO \
	ONLY_ACTIVE_ARCH=NO \
	BUILD_LIBRARY_FOR_DISTRIBUTION=YES > $OUTPUT_PATH/build_dev.log
echo "Success!"

echo "Creating xcframework..."
xcodebuild -create-xcframework \
	-framework 	   $OUTPUT_PATH/ios_dev.xcarchive/Products/usr/local/lib/PKTabbedSplitViewController.framework \
	-debug-symbols $OUTPUT_PATH/ios_dev.xcarchive/dSYMs/PKTabbedSplitViewController.framework.dSYM \
	-framework     $OUTPUT_PATH/ios_sim.xcarchive/Products/usr/local/lib/PKTabbedSplitViewController.framework \
	-debug-symbols $OUTPUT_PATH/ios_sim.xcarchive/dSYMs/PKTabbedSplitViewController.framework.dSYM \
	-output $OUTPUT_PATH/PKTabbedSplitViewController.xcframework
echo "Success!"
