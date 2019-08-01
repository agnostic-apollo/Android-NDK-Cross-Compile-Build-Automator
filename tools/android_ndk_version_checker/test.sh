#!/bin/bash


cd "$(dirname "$0")"


export ANDROID_NDK_ROOT=$HOME/Android/ndk/android-ndk-r20
export ASSERT_NDK_VERSION_FILE="assert_ndk_version.sh"
export GET_NDK_VERSION_FILE="get_ndk_version.sh"

if [ ! -d "$ANDROID_NDK_ROOT" ]; then
	echo "ANDROID_NDK_ROOT directory does not exist at $ANDROID_NDK_ROOT"
	exit 1
fi

output="$(bash "$GET_NDK_VERSION_FILE" a "$ANDROID_NDK_ROOT" 2>&1)"
if [ $? -ne 0 ]; then
	echo "Failure while running $GET_NDK_VERSION_FILE"
	echo -e "output = \n\"" && echo "$output" && echo "\""
	exit 1
fi
export NDK_FULL_VERSION="$output"
echo "NDK_FULL_VERSION=$NDK_FULL_VERSION"

output="$(bash "$GET_NDK_VERSION_FILE" m "$ANDROID_NDK_ROOT" 2>&1)"
if [ $? -ne 0 ]; then
	echo "Failure while running $GET_NDK_VERSION_FILE"
	echo -e "output = \n\"" && echo "$output" && echo "\""
	exit 1
fi
export NDK_VERSION="$output"
echo "NDK_VERSION=$NDK_VERSION"

output="$(bash "$ASSERT_NDK_VERSION_FILE" 19.0.0 "$ANDROID_NDK_ROOT" 2>&1)"
if [ $? -ne 0 ]; then
	echo "Failure while running $ASSERT_NDK_VERSION_FILE"
	echo -e "output = \n\"" && echo "$output" && echo "\""
	exit 1
fi
if [ "$output" == "true" ]; then
	NDK_VERSION_19_OR_HIGHER=1
else
	NDK_VERSION_19_OR_HIGHER=0
fi
echo "NDK_VERSION_19_OR_HIGHER=$NDK_VERSION_19_OR_HIGHER"
