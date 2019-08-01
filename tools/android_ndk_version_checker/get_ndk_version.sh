#!/bin/bash

#title:          get_ndk_version
#description:    Prints the NDK version to stdout for the NDK at ANDROID_NDK_ROOT
#                It can also print major, minor or build number.
#author:         jtjerno
#                alexs.mac
#                agnostic-apollo
#usage:          run "get_ndk_version" for detailed list of usages
#date:           1-Aug-2019
#versions:       2.0

# See https://gist.github.com/2878774 for asserting SDK version.
#
# Copyright 2012, Lookout, Inc. <jtjerno@mylookout.com>
# Licensed under the BSD license. See the zLICENSE file for information.
#
# Includes contributions from alexs.mac@gmail.com (Alex Stewart)
# Includes contributions from agnosticapollo@gmail.com (agnostic-apollo)

# In NDK versions less than 5 no version file exists
#
# In NDK version less than 11, the RELEASE.txt contains the version in r format e.g r10e
#
# In NDK version greater than or equal to 11, the source.properties contains the version in the n fomar e.g 11.0.0

# Typically used like this, in your jni/Android.mk:
#
#	ndk_version="$(shell $(LOCAL_PATH)/get_ndk_version.sh a)"
#
# Or in bash like this
#	ndk_version="$(bash $(LOCAL_PATH)/get_ndk_version.sh m /path/to/ndk)"
#
# In NDK versions less than 5 no version file exists
#
# In NDK version less than 11, the RELEASE.txt contains the version in r format e.g r10e
#
# In NDK version greater than or equal to 11, the source.properties contains the version in the n fomar e.g 11.0.0


function usage() {
echo "
Prints the NDK version to stdout for the NDK at ANDROID_NDK_ROOT.
It can also print major, minor or build number.

Usage: 
	get_ndk_version version_required
	get_ndk_version version_required [ ANDROID_NDK_ROOT ]

	version_required = {a|m|n|b}

	a -> all(r5c|19.0.1)
	m -> major(5|19)
	n -> minor(c|0)
	b -> build(|1)

For example: 
	get_ndk_version a
	get_ndk_version m
	get_ndk_version a /path/to/ndk

In NDK versions less than 5 no version file exists

export ANDROID_NDK_ROOT=/path/to/ndk before running commnad or pass ANDROID_NDK_ROOT as second paramter
"
}


R_FORMAT=0

function get_major_minor() {
	
	# Extracts 'r5c' into '5 c'
	if [[ $R_FORMAT -eq 0 ]]; then
		local version=$(echo "$1" | sed 's/r\([0-9]\{1,2\}[a-z]\).*/\1/')
		local major=$(echo "$version" | sed 's/\([0-9]\{1,2\}\).*/\1/')
		local minor=$(echo "$version" | sed 's/^[0-9]*//')
		echo "$major $minor"

	# Extract '19.0.1234567' into '19 0 1234567'
	else
		local major=$(echo "$1" | sed -En -e 's/^([0-9]+).*/\1/p') 
		local minor=$(echo "$1" | sed -En -e 's/^[0-9]+\.([0-9]+).*/\1/p')
		local build=$(echo "$1" | sed -En -e 's/^[0-9]+\.[0-9]+\.([0-9]+)/\1/p')
		echo "$major $minor $build"
	fi
}

if [[ $# -lt 1 ]] || [[ $# -gt 2 ]]; then
	usage
	exit 1
fi

if [[ "$#" -eq 2 ]]; then
	ANDROID_NDK_ROOT="$2"
	if [[ ! -d "$ANDROID_NDK_ROOT" ]]; then
		echo "Failed to find ANDROID_NDK_ROOT at the passed path $ANDROID_NDK_ROOT" >&2
		echo false
		exit 1
	fi
fi

version_required="$1"
if [[ "$version_required" == *,* ]] || [[ ",a,m,n,b," != *",$version_required,"* ]]; then	
	echo "Invalid version_required passed" >&2
	usage
	exit 1
fi


if [[ ! -d "$ANDROID_NDK_ROOT" ]]; then
	# Attempt to find ndk-build on the path.
	$(ndk-build --help 2>/dev/null)
	if [[ $? -eq 0 ]]; then
		ANDROID_NDK_ROOT=$(dirname $(which ndk-build))
	fi

	if [ ! -s "$ANDROID_NDK_ROOT" ]; then
		echo "Failed to find either ANDROID_NDK_ROOT or ndk-build" >&2
		echo false
		exit 1
	fi
fi

release_file="$ANDROID_NDK_ROOT/RELEASE.TXT"
source_properties_file="$ANDROID_NDK_ROOT/source.properties"

if [ -s "$release_file" ] && [ -s "$source_properties_file" ]; then
	echo "Both RELEASE.TXT and source.properties exist in $ANDROID_NDK_ROOT" >&2
	echo "Cannot get a reliable ndk version" >&2
	exit 1
# In NDK version less than 11, the RELEASE.txt contains the version in r format e.g r10e
elif [ -s "$release_file" ]; then
	R_FORMAT=0

	# check if ndk version in correct format
	version="$(grep '^r[0-9]\{1,2\}[a-z]' $release_file)"
	if [[ $? -ne 0 ]]; then
		echo "RELEASE.TXT contains the version number in an invalid format" >&2
		exit 1
	fi
	# extract ndk version
	version=$(sed -En -e 's/^(r[0-9]+[a-z]).*/\1/p' $release_file)

	declare -a actual_version
	actual_version=( $(get_major_minor "$version") )
	#echo "'${actual_version[0]}' '${actual_version[1]}'"

	if [[ "$version_required" == "a" ]]; then
		echo "r${actual_version[0]}${actual_version[1]}"
	elif [[ "$version_required" == "m" ]]; then
		echo "${actual_version[0]}"
	elif [[ "$version_required" == "n" ]]; then
		echo "${actual_version[1]}"
	fi
# In NDK version greater than or equal to 11, the source.properties contains the version in the n fomar e.g 11.0.0
elif [ -s "$source_properties_file" ]; then
	R_FORMAT=1

	# check if ndk version in correct format
	version="$(grep '^Pkg.Revision\s*=\s*[0-9]\{2,3\}\.[0-9]\{1,3\}\.[0-9]\{1,7\}' $source_properties_file)"
	if [[ $? -ne 0 ]]; then
		echo "source.properties contains the version number in an invalid format" >&2
		exit 1
	fi
	# extract ndk version
	version=$(sed -En -e 's/^Pkg.Revision\s*=\s*([0-9a-f]+)/\1/p' $source_properties_file)

	declare -a actual_version
	actual_version=( $(get_major_minor "$version") )
	#echo "'${actual_version[0]}' '${actual_version[1]}' '${actual_version[2]}'"

	if [[ "$version_required" == "a" ]]; then
		echo "${actual_version[0]}.${actual_version[1]}.${actual_version[2]}"
	elif [[ "$version_required" == "m" ]]; then
		echo "${actual_version[0]}"
	elif [[ "$version_required" == "n" ]]; then
		echo "${actual_version[1]}"
	elif [[ "$version_required" == "b" ]]; then
		echo "${actual_version[2]}"
	fi
# In NDK versions less than 5 no version file exists or the version file has been deleted 
else 
	echo "Neither RELEASE.TXT nor source.properties exist in $ANDROID_NDK_ROOT" >&2
	exit 1
fi



