#!/bin/bash

# Script to remove arm64e architecture and fix MinimumOSVersion in all FFmpeg-related frameworks
# This fixes the App Store validation errors for iOS 26 SDK requirement and minimum OS version

# Exit on error for critical operations
set -e

FRAMEWORKS_DIR="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}"
# Get the app's deployment target from build settings
MIN_OS_VERSION="${IPHONEOS_DEPLOYMENT_TARGET:-18.6}"

# List of FFmpeg-related frameworks to process
FFMPEG_FRAMEWORKS=(
    "ffmpegkit.framework"
    "FFmpeg.framework"
    "libavcodec.framework"
    "libavdevice.framework"
    "libavfilter.framework"
    "libavformat.framework"
    "libavutil.framework"
    "libswresample.framework"
    "libswscale.framework"
)

echo "🔍 Processing FFmpeg frameworks for distribution..."
echo "📦 Frameworks directory: ${FRAMEWORKS_DIR}"
echo "📱 Minimum OS Version: ${MIN_OS_VERSION}"
echo ""

if [ ! -d "${FRAMEWORKS_DIR}" ]; then
    echo "❌ Frameworks directory not found: ${FRAMEWORKS_DIR}"
    exit 1
fi

for FRAMEWORK_NAME in "${FFMPEG_FRAMEWORKS[@]}"; do
    FRAMEWORK_PATH="${FRAMEWORKS_DIR}/${FRAMEWORK_NAME}"
    # Binary name is typically the framework name without .framework extension
    BINARY_NAME="${FRAMEWORK_NAME%.framework}"
    BINARY_PATH="${FRAMEWORK_PATH}/${BINARY_NAME}"
    INFO_PLIST_PATH="${FRAMEWORK_PATH}/Info.plist"
    
    if [ ! -d "$FRAMEWORK_PATH" ]; then
        echo "⚠️  ${FRAMEWORK_NAME} not found at ${FRAMEWORK_PATH}"
        continue
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 Processing ${FRAMEWORK_NAME}..."
    
    # Step 1: Strip arm64e architecture
    if [ -f "$BINARY_PATH" ]; then
        ARCHS=$(lipo -info "$BINARY_PATH" 2>/dev/null | awk -F': ' '{print $3}' || echo "")
        
        if [ -z "$ARCHS" ]; then
            echo "  ⚠️  Could not read architectures from binary"
        else
            echo "  Current architectures: $ARCHS"
            
            if echo "$ARCHS" | grep -q "arm64e"; then
                echo "  🔧 Removing arm64e architecture..."
                if lipo "$BINARY_PATH" -remove arm64e -output "${BINARY_PATH}.tmp" 2>/dev/null; then
                    mv "${BINARY_PATH}.tmp" "$BINARY_PATH"
                    NEW_ARCHS=$(lipo -info "$BINARY_PATH" 2>/dev/null | awk -F': ' '{print $3}' || echo "")
                    echo "  ✅ Successfully removed arm64e"
                    echo "  Remaining architectures: $NEW_ARCHS"
                else
                    echo "  ❌ Failed to remove arm64e architecture"
                    exit 1
                fi
            else
                echo "  ✅ arm64e not found, skipping"
            fi
        fi
    else
        echo "  ⚠️  Binary not found at ${BINARY_PATH}"
    fi
    
    # Step 2: Update MinimumOSVersion in Info.plist
    if [ -f "$INFO_PLIST_PATH" ]; then
        CURRENT_MIN_OS=$(plutil -extract MinimumOSVersion raw "$INFO_PLIST_PATH" 2>/dev/null || echo "")
        
        if [ -n "$CURRENT_MIN_OS" ]; then
            echo "  Current MinimumOSVersion: ${CURRENT_MIN_OS}"
            
            # Compare versions - if current is less than required, update it
            if [ "$CURRENT_MIN_OS" != "$MIN_OS_VERSION" ]; then
                echo "  🔧 Updating MinimumOSVersion to ${MIN_OS_VERSION}..."
                if plutil -replace MinimumOSVersion -string "$MIN_OS_VERSION" "$INFO_PLIST_PATH" 2>/dev/null; then
                    echo "  ✅ Successfully updated MinimumOSVersion"
                else
                    echo "  ❌ Failed to update MinimumOSVersion"
                    exit 1
                fi
            else
                echo "  ✅ MinimumOSVersion already correct"
            fi
        else
            echo "  ⚠️  Could not read MinimumOSVersion from Info.plist"
            # Try to add it if it doesn't exist
            echo "  🔧 Adding MinimumOSVersion..."
            if plutil -insert MinimumOSVersion -string "$MIN_OS_VERSION" "$INFO_PLIST_PATH" 2>/dev/null; then
                echo "  ✅ Added MinimumOSVersion"
            else
                echo "  ❌ Failed to add MinimumOSVersion"
                exit 1
            fi
        fi
    else
        echo "  ⚠️  Info.plist not found at ${INFO_PLIST_PATH}"
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✨ Finished processing all FFmpeg frameworks"

