#!/bin/bash

#title:          assert_ndk_version
#description:    Assert that the NDK at ANDROID_NDK_ROOT is at least the required_version. 
#                Prints 'true' to stdout if NDK version is equal to or higher than the required_version, otherwise prints 'false'
#author:         jtjerno
#                alexs.mac
#                agnostic-apollo
#usage:          run "assert_ndk_version" for detailed list of usages
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
#	 ifneq ($(shell $(LOCAL_PATH)/assert_ndk_version.sh "r5c"),true)
#		$(error NDK version r5c or greater required)
#	 endif
#	 or
#	 ifneq ($(shell $(LOCAL_PATH)/assert_ndk_version.sh "19.0.0"),true)
#		$(error NDK version 19.0.0 or greater required)
#	 endif
#
# Or in bash like this
#	 if [ "$(bash /path/to/assert_ndk_version.sh 19.0.0 /path/to/ndk)" != "true" ]; then
#		echo "NDK version 19.0 or greater required" >&2
#		exit 1
#	 fi



function usage() {
echo "
Assert that the NDK at ANDROID_NDK_ROOT is at least the required_version. 
Prints 'true' to stdout if NDK version is equal to or higher than the required_version, otherwise prints 'false'

Usage: 
	assert_ndk_version required_version
	assert_ndk_version required_version [ ANDROID_NDK_ROOT ]
For example: 
	assert_ndk_version r5c
	assert_ndk_version 19.0.0
	assert_ndk_version 19.0.0 /path/to/ndk

required_version should be in r format -> \"r<major><minor>\" i.e \"r[0-9]{1,2}[a-z]\" for checking NDK version greater than equal \
to 5 and less than 11

required_version should be in number format -> \"<major>.<minor>.<build>\" i.e \"[0-9]{2,3}.[0-9]{1,3}.[0-9]{1,7}\" for checking \
NDK version greater than or equal to 11

where \"[0-9]{n1,n2}\" means between n1-n2 digits and \"[a-z]\" means a single alphabet character

In NDK versions less than 5 no version file exists and cannot be tested

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

R_FORMAT="$(echo "$1" | grep -q '^r[0-9]\{1,2\}[a-z]$' && echo 0 || echo 1)"
if [[ $R_FORMAT -ne 0 ]]; then
	N_FORMAT="$(echo "$1" | grep -q '^[0-9]\{2,3\}\.[0-9]\{1,3\}\.[0-9]\{1,7\}$' && echo 0 || echo 1)"
	if [[ $N_FORMAT -ne 0 ]]; then
		echo "Invalid version format passed" >&2
		usage
		exit 1
	fi
fi


# Assert that the expected version is at least 4.
declare -a expected_version
expected_version=( $(get_major_minor "$1") )
if [[ ${expected_version[0]} -le 4 ]]; then
	echo "Cannot test for NDK versions less than 5 since no version file exists" >&2
	echo false
	exit 1
fi

if [[ $R_FORMAT -eq 0 ]] && [[ ${expected_version[0]} -ge 11 ]]; then
	echo "Major versions greater than 10 require the number format" >&2
	echo false
	exit 1
fi

if [[ $R_FORMAT -ne 0 ]] && [[ ${expected_version[0]} -lt 11 ]]; then
	echo "Major versions less than 11 require the r format" >&2
	echo false
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
	echo "Cannot get a reliable NDK version" >&2
	echo false
	exit 1
fi

# In NDK version less than 11, the RELEASE.txt contains the version in r format e.g r10e
if [ -s "$release_file" ] && [[ $R_FORMAT -eq 0 ]]; then

	# check if ndk version in correct format
	version="$(grep '^r[0-9]\{1,2\}[a-z]' $release_file)"
	if [[ $? -ne 0 ]]; then
		echo "RELEASE.TXT contains the version number in an invalid format" >&2
		echo false
		exit 1
	fi
	# extract ndk version
	version=$(sed -En -e 's/^(r[0-9]+[a-z]).*/\1/p' $release_file)

	declare -a actual_version
	actual_version=( $(get_major_minor "$version") )
	#echo "'${actual_version[0]}' '${actual_version[1]}'"

	if [ -z "$version" ] || [ -z "${actual_version[0]}" ] || [ -z "${actual_version[1]}" ]; then
		echo "Invalid RELEASE.txt: $(cat $release_file)" >&2
		echo false
		exit 1
	fi

	if [[ ${actual_version[0]} -lt ${expected_version[0]} ]]; then
		echo "false"
	elif [[ ${actual_version[0]} -eq ${expected_version[0]} ]]; then
		# This uses < and not -lt because they're string identifiers (a, b, c, etc)
		if [[ "${actual_version[1]}" < "${expected_version[1]}" ]]; then
			echo "false"
		else
			echo "true"
		fi
	else
		echo "true"
	fi
# In NDK version greater than or equal to 11, the source.properties contains the version in the n fomar e.g 11.0.0
elif [ -s "$source_properties_file" ] && [[ $R_FORMAT -eq 1 ]]; then

	# check if ndk version in correct format
	version="$(grep '^Pkg.Revision\s*=\s*[0-9]\{2,3\}\.[0-9]\{1,3\}\.[0-9]\{1,7\}' $source_properties_file)"
	if [[ $? -ne 0 ]]; then
		echo "source.properties contains the version number in an invalid format" >&2
		echo false
		exit 1
	fi
	# extract ndk version
	version=$(sed -En -e 's/^Pkg.Revision\s*=\s*([0-9a-f]+)/\1/p' $source_properties_file)

	declare -a actual_version
	actual_version=( $(get_major_minor "$version") )
	#echo "'${actual_version[0]}' '${actual_version[1]}' '${actual_version[2]}'"

	if [ -z "$version" ] || [ -z "${actual_version[0]}" ] || [ -z "${actual_version[1]}" ] \
		|| [ -z "${actual_version[2]}" ]; then
		echo "Invalid source.properties: $(cat $source_properties_file)" >&2
		echo false
		exit 1
	fi

	if [[ ${actual_version[0]} -lt ${expected_version[0]} ]]; then
		echo "false"
	elif [[ ${actual_version[0]} -eq ${expected_version[0]} ]]; then
		if [[ ${actual_version[1]} -lt ${expected_version[1]} ]]; then
			echo "false"
		elif [[ ${actual_version[1]} -eq ${expected_version[1]} ]]; then
			if [[ ${actual_version[2]} -lt ${expected_version[2]} ]]; then
				echo "false"
			else
				echo "true"
			fi
		else
			echo "true"
		fi
	else
		echo "true"
	fi
# In NDK versions less than 5 no version file exists or the version file has been deleted 
else 
	echo false
	exit 0
fi



