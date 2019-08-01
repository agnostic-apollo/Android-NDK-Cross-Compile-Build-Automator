#!/bin/bash
#title:          android_ndk_cross_compile_build_automator
#description:    cross compile multiple projects with NDK for Android for multiple archs
#author:         agnostic-apollo
#usage:          run "bash ./android_ndk_cross_compile_build_automator.sh" after setting USER MODIFIABLE VARIABLES in the script appropriately 
#date:           1-Aug-2019
#versions:       1.0
#license:        MIT License

#sudo apt install autoconf automake libtool

cd "$(dirname "$0")"
export PARENT_DIRECTORY="$(	pwd -P )" #get the current directory in which script is running




#USER MODIFIABLE VARIABLES START

#set the space separated list of ARCH_SRC files in ARCHS_DIR that you want to build for
#ARCHS_SRC_TO_BUILD="armeabi-android4.0.4- armeabi armeabi-v7a arm64-v8a x86 x86-64"
ARCHS_SRC_TO_BUILD="armeabi armeabi-v7a arm64-v8a x86 x86-64"

#set the space separated list of project directories in PROJECTS_DIR that you want to build
#the root of each project directory must contain the BUILD_FILE_NAME file that build and installs the project
#PROJECTS_TO_BUILD="fuse"
PROJECTS_TO_BUILD=""

#set the space separated list of post build scripts files in POST_BUILD_SCRIPTS_DIR that you want to run
#POST_BUILD_SCRIPTS_TO_RUN="fusermount_extractor.sh"
POST_BUILD_SCRIPTS_TO_RUN=""


#set path to NDK
export ANDROID_NDK_ROOT="$HOME/Android/ndk/android-ndk-r20"
#set path to the directory in which NDK toolchains should be created,
#if prebuilt toolchains are not available or CREATE_TEMP_TOOLCHAINS is not set to "1"
export TOOLCHAIN_DIR_PREFIX="$HOME/Android/ndk-toolchains"


#set this to "0" if you want to build toolchains if required and then build projects
#set this to "1" if you only want to build toolchains for each enabled ARCH_SRC in TOOLCHAIN_DIR_PREFIX and not build projects
ONLY_BUILD_TOOLCHAINS=0
#set this to "0" if you do not want to use prebuilt toolchains and want to build them at runtime before building projects
#set this to "1" if you want to use prebuilt toolchains if available, only available in ndk versions greater than 19
USE_PREBUILT_TOOLCHAINS_IF_AVAILABLE=1
#set this to "0" if you do not want toolchains to be built in /tmp directory and want them built in TOOLCHAIN_DIR_PREFIX for future reuse
#set this to "1" if you want to toolchains to be built in /tmp directory at runtime, and then deleted after use
#each toolchain for a specific ARCH_SRC takes about 1-2GB of hard disk space and building for 4-5 ARCH_SRCs can take lot of space,
#it is advisable to set this to "1" if you have limited space, otherwise you will get errors while building toolchains if no free space is left in hard disk 
CREATE_TEMP_TOOLCHAINS=0
#set this to "0" if you do not want toolchains in TOOLCHAIN_DIR_PREFIX to be removed and rebuilt before building projects
#set this to "1" if you want toolchains in TOOLCHAIN_DIR_PREFIX to be removed and rebuilt before building projects,
#might be useful if you messed around with the toolchain and corrupted it or updated the ndk
REMOVE_TOOLCHAIN_AND_REBUILD_BEFORE_BUILDING=0
#set this to "0" if you want to use clang/clang++ instead of gcc/g++ if your ndk version is greater than 15 
#set this to "1" if you want to use gcc/g++ instead of clang/clang++ if your ndk version is less than 18
#clang for introduced in ndk version 15 and gcc was deprecated but it stayed until ndk version 18 in which it was removed
USE_GCC_INSTEAD_OF_CLANG_UNDER_NDK_VERSION_18=0
#set this to "0" if you do not want to copy each project in the PROJECTS_DIR to BUILD_DIR before building
#set this to "1" if you want to copy each project in the PROJECTS_DIR to BUILD_DIR before building
#building usually messes up the project source directory and leaves unnecessary files later,
#setting this to "1" ensures that your original project source directory is not modified for release
#however if your project source directory uses a lot of hard disk space, then you will need to use this flag accordingly
COPY_PROJECTS_TO_BUILD_DIR_BEFORE_BUILDING=1
#set this to "0" if you do not want to delete the install directory before projects are built
#set this to "1" if you want to delete the install directory before projects are built
#this is useful if you want a fresh install directory when ever you build and install projects,
#so that files from previous installs are not merged with the current one
#however if you enable a build of a certain project in one run of the script, and then enable build of another project
#in another run of the script, the installed files of the first project will be deleted when you run the script the second time
#so make you extract the installed files of the first project using post build scripts so that they are not deleted later
#you can optionally also use INSTALL_DIR="$INSTALL_DIR/$(date +"%Y-%m-%d %H.%M.%S")", to add a timestamp for each install
REMOVE_INSTALL_DIR_BEFORE_BUILDING=1
#set this to "0" if you do not want to remove the BUILD_DIR after building
#set this to "1" if you want to remove the BUILD_DIR after building (Not the PROJECTS_DIR)
#if you have set this to "1", then make sure you run "make install" in your projects build file,
#so that the files built are moved to the INSTALL_DIR, otherwise they will be deleted
#this flag is ignored if you have set COPY_PROJECTS_TO_BUILD_DIR_BEFORE_BUILDING to "0"
REMOVE_BUILD_DIR_AFTER_BUILDING=1
#set this to "0" if you do not want to run post build scripts in the POST_BUILD_SCRIPTS_DIR
#set this to "1" if you want to run post build scripts in the POST_BUILD_SCRIPTS_DIR
RUN_POST_BUILD_SCRIPTS=1
#set this to "0" if you do not want to redirect stdout and stderr of build file and post build scripts to BUILD_AND_POST_BUILD_LOG_FILE
#set this to "1" if you want to redirect stdout and stderr of build file and post build scripts to BUILD_AND_POST_BUILD_LOG_FILE
REDIRECT_BUILD_AND_POST_BUILD_OUTPUT_TO_LOG_FILE=0


# do not modify below variables unless you know what you are doing
export ARCHS_DIR="$PARENT_DIRECTORY/config/archs" #set path to the directory in which ARCH_SRC files are stored
export PROJECTS_DIR="$PARENT_DIRECTORY/projects" #set path to the directory in which projects are stored
export TOOLS_DIR="$PARENT_DIRECTORY/tools" #set path to the directory in which tools that are used are stored
export BUILD_DIR="$PARENT_DIRECTORY/build" #set path to the directory in which projects should be copied to before building
export INSTALL_DIR="$PARENT_DIRECTORY/install" #set path to the directory in which projects are installed
export POST_BUILD_SCRIPTS_DIR="$PARENT_DIRECTORY/post_build_scripts" #set path to the directory in which post build scripts are stored
export OUT_DIR="$PARENT_DIRECTORY/out" #set path to the directory which post build scripts can use to extract relevant binaries/libs
export ASSERT_NDK_VERSION_FILE="$TOOLS_DIR/android_ndk_version_checker/assert_ndk_version.sh" #set path to script that is used to assert NDK version
export GET_NDK_VERSION_FILE="$TOOLS_DIR/android_ndk_version_checker/get_ndk_version.sh" #set path to script that is used to get NDK version
export SETUP_DEFAULTS_FILE="$TOOLS_DIR/setup_defaults" #set path to script that is used to set and get important host and NDK related variables 
export BUILD_FILE_NAME="android_ndk_cross_compile_build.sh" #set name of the build file that each project should have in its root folder
export BUILD_AND_POST_BUILD_LOG_FILE="$PARENT_DIRECTORY/configure_and_make_log_file.log" #set path to log file to be used if needed
export MAKE_STANDALONE_TOOLCHAIN_FILE="$ANDROID_NDK_ROOT/build/tools/make-standalone-toolchain.sh" #set path to make-standalone-toolchain script


#USER MODIFIABLE VARIABLES END




#store the flags set in the env at the time this script is run so that they can be added to flags set by ARCH_SRC files
OLD_CPPFLAGS="$CPPFLAGS"
OLD_CFLAGS="$CFLAGS"
OLD_CXXFLAGS="$CXXFLAGS"
OLD_LDFLAGS="$LDFLAGS"
CREATING_TEMP_TOOLCHAIN=0

#set the exit code values that the BUILD_FILE should return in case of non catastrophic failure
export UNSUPPORTED_C_COMPILER_EXIT_CODE=111
export UNSUPPORTED_CXX_COMPILER_EXIT_CODE=112
export UNSUPPORTED_ARCH_SRC_EXIT_CODE=113

#validate that the following variables do not contain any whitespace characters
for p in ANDROID_NDK_ROOT TOOLCHAIN_DIR_PREFIX PARENT_DIRECTORY \
	PROJECTS_DIR ARCHS_DIR TOOLS_DIR BUILD_DIR INSTALL_DIR POST_BUILD_SCRIPTS_DIR OUT_DIR \
		ASSERT_NDK_VERSION_FILE GET_NDK_VERSION_FILE SETUP_DEFAULTS_FILE BUILD_FILE_NAME \
			BUILD_AND_POST_BUILD_LOG_FILE; do
	if [[ "${!p}" =~ [[:space:]] ]]; then
		echo "Whitespaces are not allowed in path: \"$p=${!p}\""
		exit 1
	fi
done

#validate that the directory name of any directory in the PROJECTS_DIR does not contain any whitespace characters
for PROJECT_DIR in "$PROJECTS_DIR"/*; do
	if [ -d "$PROJECT_DIR" ]; then
		PROJECT="$(basename "$PROJECT_DIR")"
		if [[ "$PROJECT" =~ [[:space:]] ]]; then
			echo "Whitespaces are not allowed in PROJECT name: \"$PROJECT\""
			exit 1
		fi
	fi
done

#validate that the filename of any ARCH_SRC file in the ARCHS_DIR does not contain any whitespace characters
for ARCH_FILE in "$ARCHS_DIR"/*; do
	if [ -f "$ARCH_FILE" ]; then
		ARCH_SRC="$(basename "$ARCH_FILE")"
		if [[ "$ARCH_SRC" =~ [[:space:]] ]]; then
			echo "Whitespaces are not allowed in ARCH_SRC name: \"$ARCH_SRC\""
			exit 1
		fi
	fi
done

#validate that the filename of any POST_BUILD_SCRIPT_FILE in the POST_BUILD_SCRIPTS_DIR does not contain any whitespace characters
for POST_BUILD_SCRIPT_FILE in "$POST_BUILD_SCRIPTS_DIR"/*; do
	if [ -f "$POST_BUILD_SCRIPT_FILE" ]; then
		POST_BUILD_SCRIPT="$(basename "$POST_BUILD_SCRIPT_FILE")"
		if [[ "$POST_BUILD_SCRIPT" =~ [[:space:]] ]]; then
			echo "Whitespaces are not allowed in POST_BUILD_SCRIPT name: \"$POST_BUILD_SCRIPT\""
			exit 1
		fi
	fi
done

#validate if ANDROID_NDK_ROOT directory exists
if [ ! -d "$ANDROID_NDK_ROOT" ]; then
	echo "ANDROID_NDK_ROOT directory does not exist at $ANDROID_NDK_ROOT"
	exit 1
fi

#if ONLY_BUILD_TOOLCHAINS is set to "1",
#then temp toolchains should not created but toolchains should be created in TOOLCHAIN_DIR_PREFIX
#nor should any USE_PREBUILT_TOOLCHAINS_IF_AVAILABLE processing be done
if [ $ONLY_BUILD_TOOLCHAINS -eq 1 ]; then
	CREATE_TEMP_TOOLCHAINS=0
	USE_PREBUILT_TOOLCHAINS_IF_AVAILABLE=0
fi

#get the full version of the NDK at the ANDROID_NDK_ROOT
output="$(bash "$GET_NDK_VERSION_FILE" a "$ANDROID_NDK_ROOT" 2>&1)"
if [ $? -ne 0 ]; then
	echo "Failure while running $GET_NDK_VERSION_FILE"
	echo -e "output = \n\"" && echo "$output" && echo "\""
	exit 1
fi
export NDK_FULL_VERSION="$output"
echo "NDK_FULL_VERSION=$NDK_FULL_VERSION"

#get the major version of the NDK at the ANDROID_NDK_ROOT
output="$(bash "$GET_NDK_VERSION_FILE" m "$ANDROID_NDK_ROOT" 2>&1)"
if [ $? -ne 0 ]; then
	echo "Failure while running $GET_NDK_VERSION_FILE"
	echo -e "output = \n\"" && echo "$output" && echo "\""
	exit 1
fi
export NDK_VERSION="$output"
echo "NDK_VERSION=$NDK_VERSION"

#check if the version of the NDK at the ANDROID_NDK_ROOT is atleast 19.0.0
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


#only NDK version 19 and above has prebuilt toolchains for all archs except arm(not armv7)
if [ $NDK_VERSION_19_OR_HIGHER -eq 1 ]; then
	PREBUILT_TOOLCHAINS_AVAILABLE=1
else
	PREBUILT_TOOLCHAINS_AVAILABLE=0
fi


#set USE_PREBUILT_TOOLCHAINS to "1" only if user has specified to use prebuilt toolchains 
#and prebuilt toolchains are supposed to be available based on NDK version check
USE_PREBUILT_TOOLCHAINS=0
if [ $USE_PREBUILT_TOOLCHAINS_IF_AVAILABLE -eq 1 ]; then
	if [ $PREBUILT_TOOLCHAINS_AVAILABLE -eq 1 ]; then
		echo "Prebuilt toolchains should be available with the ndk version of the ndk at $ANDROID_NDK_ROOT"
		echo "Prebuilt toolchains will be used"
		USE_PREBUILT_TOOLCHAINS=1
	else
		echo "Prebuilt toolchains are not available with the ndk version of the ndk at $ANDROID_NDK_ROOT"
		echo "Toolchains will need to be built"
	fi
fi

#source the SETUP_DEFAULTS_FILE to setup important host and NDK related variables and define helpful functions to be used later
source "$SETUP_DEFAULTS_FILE"
if [ $? -ne 0 ]; then
	echo "Failure while running $SETUP_DEFAULTS_FILE"
	exit 1
fi
export HOST_TAG
export API_LEVELS
export LATEST_API_LEVEL

#validate if ARCHS_DIR exists
if [ ! -d "$ARCHS_DIR" ] || \
	[ -n "$(find "$ARCHS_DIR" -maxdepth 0 -type f -empty 2>/dev/null)" ]; then
	echo "The $ARCHS_DIR directory does not exist or is empty, place arch files into it and run again"
	exit 1
fi

#if projects also need to built and not just toolchains
if [ $ONLY_BUILD_TOOLCHAINS -ne 1 ]; then

	#validate if PROJECTS_DIR exists
	if [ ! -d "$PROJECTS_DIR" ] || \
		[ -n "$(find "$PROJECTS_DIR" -maxdepth 0 -type d -empty 2>/dev/null)" ]; then
		echo "The $PROJECTS_DIR directory does not exist or is empty, place projects into it and run again"
		exit 1
	fi

	#if COPY_PROJECTS_TO_BUILD_DIR_BEFORE_BUILDING is set to "1" then, copy all projects in PROJECTS_DIR to BUILD_DIR
	if [ $COPY_PROJECTS_TO_BUILD_DIR_BEFORE_BUILDING -eq 1 ]; then
		ORIGINAL_BUILD_DIR="$BUILD_DIR"
		echo "Removing $BUILD_DIR directory contents and then copying all projects into it"
		rm -rf "$BUILD_DIR" && mkdir -p "$BUILD_DIR" && cp -a "$PROJECTS_DIR"/. "$BUILD_DIR"/
		if [ $? -ne 0 ]; then
			echo "Failed"
			exit 1
		fi
	else
		BUILD_DIR="$PROJECTS_DIR"
	fi

	#if REMOVE_INSTALL_DIR_BEFORE_BUILDING is set to "1", then remove it and create and empty one 
	if [ $REMOVE_INSTALL_DIR_BEFORE_BUILDING -eq 1 ]; then
		echo "Removing $INSTALL_DIR directory contents"
		rm -rf "$INSTALL_DIR" && mkdir -p "$INSTALL_DIR"
		if [ $? -ne 0 ]; then
			echo "Failed"
			exit 1
		fi
	fi

	#if RUN_POST_BUILD_SCRIPTS is set to "1" and POST_BUILD_SCRIPTS_DIR does not exist, then create an empty one for future use
	if [ $RUN_POST_BUILD_SCRIPTS -eq 1 ] && [ ! -d "$POST_BUILD_SCRIPTS_DIR" ]; then
			echo "Creating $POST_BUILD_SCRIPTS_DIR directory since it does not exist"
			mkdir -p "$POST_BUILD_SCRIPTS_DIR"
			if [ $? -ne 0 ]; then
				echo "Failed"
				exit 1
			fi
	fi
	
	#if REDIRECT_BUILD_AND_POST_BUILD_OUTPUT_TO_LOG_FILE is set to "1",
	#then clear and validate BUILD_AND_POST_BUILD_LOG_FILE
	if [ $REDIRECT_BUILD_AND_POST_BUILD_OUTPUT_TO_LOG_FILE -eq 1 ]; then
		echo "" > "$BUILD_AND_POST_BUILD_LOG_FILE"
		if [ $? -ne 0 ]; then
			echo "Failure to create BUILD_AND_POST_BUILD_LOG_FILE=$BUILD_AND_POST_BUILD_LOG_FILE"
			exit 1
		fi
	fi
fi

#a function to check if the toolchain set based on ARCH_SRC is valid
function toolchain_validation() {

	#validate if toolchain directories exists
	for d in TOOLCHAIN_DIR SYSROOT TOOLCHAIN_BIN_DIR; do
		if [ ! -z "${!d}" ]; then
			if [ ! -d "${!d}" ]; then
				echo "Failed to find required directory \"$d=${!d}\""
				return 1
			fi
		fi
	done

	#validate if compiler and bintools exist
	for f in CPP CC CXX LD AR AS NM RANLIB STRIP; do
		if [ ! -z "${!f}" ]; then
			if [ ! -f "${!f}" ]; then
				echo "Failed to find required file \"$f=${!f}\""
				return 1
			fi
		fi
	done

}

#remove the temp TOOLCHAIN_DIR directory if temp toolchains had to created
function cleanup() {

	if [ $CREATING_TEMP_TOOLCHAIN -eq 1 ] && [ ! -z "$TOOLCHAIN_DIR" ]; then
		echo "Removing temporary toolchain $TOOLCHAIN_DIR"
		rm -rf "$TOOLCHAIN_DIR"
		if [ $? -ne 0 ]; then
			echo "Failed"
			exit 1
		fi
		CREATING_TEMP_TOOLCHAIN=0
		TOOLCHAIN_DIR=""
	fi

}
#setup trap to call cleanup on exit
trap cleanup EXIT

#cd to PARENT_DIRECTORY before beginning build process
cd "$PARENT_DIRECTORY"

#for all ARCH_FILEs in the ARCHS_DIR
for ARCH_FILE in "$ARCHS_DIR"/*; do

	#if not a regular file, then skip
	if [ ! -f "$ARCH_FILE" ]; then
		continue
	fi

	#get ARCH_SRC from basename of ARCH_FILE
	export ARCH_SRC="$(basename "$ARCH_FILE")"

	#if ARCH_SRC is not defined in the ARCHS_SRC_TO_BUILD, then skip
	if [[ ! "$ARCHS_SRC_TO_BUILD" =~ (^|[[:space:]])"$ARCH_SRC"($|[[:space:]]) ]]; then
		echo "Skipping build for $ARCH_SRC"
		continue
	fi

	#cd to PARENT_DIRECTORY before building for each ARCH_SRC
	cd "$PARENT_DIRECTORY"
	echo -e "\n\n\n\n\n"
	echo "Processing ARCH_SRC $ARCH_SRC"

	#clear all variables
	for variable in ARCH API_LEVEL CPPFLAGS CXXFLAGS LDFLAGS ABI_NAME \
		TOOLCHAIN_DIR SYSROOT TOOLCHAIN_BIN_DIR TOOLCHAIN_PREFIX \
			C_COMPILER CXX_COMPILER CPP CC CXX LD AR AS NM RANLIB STRIP; do
		export ${variable}=""
	done
	
	#source the ARCH_SRC to set all the variables defined in it
	source "$ARCH_FILE"

	#export all variables set by ARCH_SRC and add old flags to flags set by ARCH_SRC
	export ARCH
	export API_LEVEL
	export CPPFLAGS="$OLD_CPPFLAGS $CPPFLAGS"
	export CFLAGS="$OLD_CFLAGS $CFLAGS"
	export CXXFLAGS="$OLD_CXXFLAGS $CXXFLAGS"
	export LDFLAGS="$OLD_LDFLAGS $LDFLAGS"

	#if ARCH contains a whitespace or is not supported by the NDK
	if [[ "$ARCH" =~ [[:space:]] ]] || \
		[[ ! "$SUPPORTED_ARCHS" =~ (^|[[:space:]])"$ARCH"($|[[:space:]]) ]]; then
		echo "ARCH='$ARCH' is invalid or not supported by the NDK"
		echo "Valid SUPPORTED_ARCHS=\"$SUPPORTED_ARCHS\""
		exit 1
	fi

	#if API_LEVEL contains a whitespace or is not supported by the current NDK version
	if [[ "$API_LEVEL" =~ [[:space:]] ]] || \
		[[ ! "$API_LEVELS" =~ (^|[[:space:]])"$API_LEVEL"($|[[:space:]]) ]]; then
		echo "API_LEVEL='$API_LEVEL' is invalid or not supported by NDK version $NDK_VERSION"
		echo "Valid API_LEVELS=\"$API_LEVELS\""
		exit 1
	fi

	#get ABI for current ARCH
	output="$(get_abi_for_arch "$ARCH" 2>&1)"
	if [ $? -ne 0 ]; then
		echo "Failed to get ABI_NAME for $ARCH"
		echo -e "output = \n\"" && echo "$output" && echo "\""
		exit 1
	fi
	export ABI_NAME="$output"

	#get toolchain prefix used by NDK for current ARCH
	output="$(get_default_toolchain_prefix_for_arch "$ARCH")"
	if [ $? -ne 0 ] || [ -z "$output" ]; then
		echo "Failed to get TOOLCHAIN_PREFIX for $ARCH"
		echo -e "output = \n\"" && echo "$output" && echo "\""
		exit 1
	fi
	export TOOLCHAIN_PREFIX="$output"

	#get toolchain compiler prefix used by NDK for current ARCH and NDK_VERSION
	output="$(get_default_toolchain_compiler_prefix_for_arch "$ARCH" "$NDK_VERSION")"
	if [ $? -ne 0 ] || [ -z "$output" ]; then
		echo "Failed to get TOOLCHAIN_COMPILER_PREFIX for $ARCH"
		echo -e "output = \n\"" && echo "$output" && echo "\""
		exit 1
	fi
	export TOOLCHAIN_COMPILER_PREFIX="$output"

	#get toolchain bintools prefix used by NDK for current ARCH
	output="$(get_default_toolchain_bintools_prefix_for_arch "$ARCH")"
	if [ $? -ne 0 ] || [ -z "$output" ]; then
		echo "Failed to get TOOLCHAIN_BINTOOLS_PREFIX for $ARCH"
		echo -e "output = \n\"" && echo "$output" && echo "\""
		exit 1
	fi
	export TOOLCHAIN_BINTOOLS_PREFIX="$output"

	#export TARGET_HOST that can be used by build scripts
	export TARGET_HOST=$TOOLCHAIN_PREFIX

	#reset USE_PREBUILT_TOOLCHAINS to "1", if overridden by a previous loop,
	#if prebuilt toolchains were not available only for a specific ABI or API_LEVEL
	if [ $USE_PREBUILT_TOOLCHAINS_IF_AVAILABLE -eq 1 ] && [ $PREBUILT_TOOLCHAINS_AVAILABLE -eq 1 ]; then
		USE_PREBUILT_TOOLCHAINS=1
	fi

	#if prebuilt toolchains should be used
	if [ $USE_PREBUILT_TOOLCHAINS -eq 1 ]; then
		#set the default path for the prebuilt toolchains for the current HOST_TAG
		TOOLCHAIN_DIR="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/$HOST_TAG"

		#export toolchain variables
		export SYSROOT="$TOOLCHAIN_DIR/sysroot"
		export TOOLCHAIN_BIN_DIR="$TOOLCHAIN_DIR/bin"

		export C_COMPILER=clang
		export CXX_COMPILER=clang++
		export CC="$TOOLCHAIN_BIN_DIR/${TOOLCHAIN_COMPILER_PREFIX}${API_LEVEL}-clang"
		export CXX="$TOOLCHAIN_BIN_DIR/${TOOLCHAIN_COMPILER_PREFIX}${API_LEVEL}-clang++"
		export LD="$TOOLCHAIN_BIN_DIR/$TOOLCHAIN_BINTOOLS_PREFIX-ld"
		export AR="$TOOLCHAIN_BIN_DIR/$TOOLCHAIN_BINTOOLS_PREFIX-ar"
		export AS="$TOOLCHAIN_BIN_DIR/$TOOLCHAIN_BINTOOLS_PREFIX-as"
		export NM="$TOOLCHAIN_BIN_DIR/$TOOLCHAIN_BINTOOLS_PREFIX-nm"
		export RANLIB="$TOOLCHAIN_BIN_DIR/$TOOLCHAIN_BINTOOLS_PREFIX-ranlib"
		export STRIP="$TOOLCHAIN_BIN_DIR/$TOOLCHAIN_BINTOOLS_PREFIX-strip"

		#prebuilt toolchains are only available for specific ABIs and specific API levels higher than 16
		#validate the current toolchain setup
		toolchain_validation
		if [ $? -ne 0 ]; then
			echo "Prebuilt toolchain not found for TOOLCHAIN=$TOOLCHAIN_PREFIX and API_LEVEL=$API_LEVEL"
			echo "Toolchain will need to be created"
			USE_PREBUILT_TOOLCHAINS=0
		fi
	fi
	
	#if validation passed and prebuilt toolchains should be used
	if [ $USE_PREBUILT_TOOLCHAINS -eq 1 ]; then
		echo "Using prebuilt $ABI_NAME toolchain at $TOOLCHAIN_DIR"
	#else
	else

		create_toolchain=0
		
		#if temp toolchains should be created and used, then set TOOLCHAIN_DIR to a directory in /tmp and and set create_toolchain to "1"
		if [ $CREATE_TEMP_TOOLCHAINS -eq 1 ]; then
			TOOLCHAIN_DIR="$(mktemp -d)"
			TOOLCHAIN_DIR="$TOOLCHAIN_DIR/$TOOLCHAIN_PREFIX"
			CREATING_TEMP_TOOLCHAIN=1
			create_toolchain=1
		#check if toolchains already exist in TOOLCHAIN_DIR_PREFIX that were built in a previous run of the script
		else
			TOOLCHAIN_DIR="$TOOLCHAIN_DIR_PREFIX/r$NDK_VERSION/$HOST_TAG/$TOOLCHAIN_PREFIX"
			#if toolchain directory exists and REMOVE_TOOLCHAIN_AND_REBUILD_BEFORE_BUILDING is set to "1",
			#then delete toolchain directory and set create_toolchain to "1"
			if [ -d "$TOOLCHAIN_DIR" ] && [ $REMOVE_TOOLCHAIN_AND_REBUILD_BEFORE_BUILDING -eq 1 ]; then
				echo "Removing toolchain at $TOOLCHAIN_DIR since REMOVE_TOOLCHAIN_AND_REBUILD_BEFORE_BUILDING=1"
				rm -rf "$TOOLCHAIN_DIR"
				if [ $? -ne 0 ]; then
					echo "Failed"
					exit 1
				fi
				create_toolchain=1
			#else if toolchain directory exists and is not empty
			elif [ -d "$TOOLCHAIN_DIR" ] && \
				[ ! -n "$(find "$TOOLCHAIN_DIR" -maxdepth 0 -type d -empty 2>/dev/null)" ]; then
					#get the NDK_VERSION from which the toolchain was previously built
					#the toolchain must have been built with this script for this check, 
					#since this script stores the version file of NDK in the toolchain directory when it is created
					#otherwise this will fail, in that case manually delete the toolchain directory and run script again
					output="$(bash "$GET_NDK_VERSION_FILE" a "$TOOLCHAIN_DIR" 2>&1)"
					if [ $? -ne 0 ]; then
						echo "Failure while running $GET_NDK_VERSION_FILE to get NDK_VERSION_OF_TOOLCHAIN"
						echo -e "output = \n\"" && echo "$output" && echo "\""
						echo "This may be because you did not create the toolchain with this script or toolchain has been corrupted"
						echo "Remove \"$TOOLCHAIN_DIR\" manually and run script again"
						exit 1
					fi
					export NDK_VERSION_OF_TOOLCHAIN="$output"

					#if NDK version of the current NDK does not match the NDK version from which the toolchain was created,
					#then remove toolchain and set create_toolchain to "1"
					if [[ "$NDK_FULL_VERSION" != "$NDK_VERSION_OF_TOOLCHAIN" ]]; then
						echo "NDK_VERSION_OF_TOOLCHAIN=$NDK_VERSION_OF_TOOLCHAIN"
						echo "Removing toolchain at $TOOLCHAIN_DIR since NDK_VERSION_OF_TOOLCHAIN does not match current NDK_FULL_VERSION"
						rm -rf "$TOOLCHAIN_DIR"
						if [ $? -ne 0 ]; then
							echo "Failed"
							exit 1
						fi
						create_toolchain=1
					fi
			#else if toolchain directory does not exist or is empty, then set create_toolchain to "1"
			elif [ ! -d "$TOOLCHAIN_DIR" ] || \
				[ -n "$(find "$TOOLCHAIN_DIR" -maxdepth 0 -type d -empty 2>/dev/null)" ]; then
					echo "Failed to find toolchain at $TOOLCHAIN_DIR"
					create_toolchain=1
			fi

			#if toolchain should be created, then create toolchain parent directory
			#the toolchain directory iteself should not be created, otherwise MAKE_STANDALONE_TOOLCHAIN_FILE will complain and fail
			if [ $create_toolchain -eq 1 ]; then
				echo "Creating toolchain parent directory"
				mkdir -p "$TOOLCHAIN_DIR_PREFIX/r$NDK_VERSION/$HOST_TAG"
				if [ $? -ne 0 ]; then
					echo "Failed"
					exit 1
				fi
			fi
		fi

		#if toolchain should be created
		if [ $create_toolchain -eq 1 ]; then
			echo "Creating $ARCH toolchain in $TOOLCHAIN_DIR"

			#get arch to be passed to MAKE_STANDALONE_TOOLCHAIN_FILE that is compatible with it
			output="$(get_arch_for_toolchain $ARCH 2>&1)"
			if [ $? -ne 0 ]; then
				echo "Failed to get arch_for_toolchain for $ARCH"
				echo -e "output = \n\"" && echo "$output" && echo "\""
				exit 1
			fi
			arch_for_toolchain="$output"
			echo "arch_for_toolchain=$arch_for_toolchain"


			if [ ! -f "$MAKE_STANDALONE_TOOLCHAIN_FILE" ]; then
				echo "Failed to MAKE_STANDALONE_TOOLCHAIN_FILE at $MAKE_STANDALONE_TOOLCHAIN_FILE"
				exit 1
			fi

			#create toolchain for specific API_LEVEL and ARCH
			bash "$MAKE_STANDALONE_TOOLCHAIN_FILE" --install-dir="$TOOLCHAIN_DIR" \
				--platform="android-$API_LEVEL" --arch="$arch_for_toolchain"
			if [ $? -ne 0 ]; then
				echo "Failure to build toolchain"
				exit 1
			fi

			#copy the version file of NDK from which the toolchain is created to the root directory of the toolchain for future validation
			if [ "$NDK_VERSION" -lt 11 ]; then
				cp "$ANDROID_NDK_ROOT/RELEASE.TXT" "$TOOLCHAIN_DIR/"
			else
				cp "$ANDROID_NDK_ROOT/source.properties" "$TOOLCHAIN_DIR/"
			fi
		#else if toolchain already exists
		else
			echo "Not creating toolchain since toolchain directory already exists at $TOOLCHAIN_DIR"
		fi

		#export toolchain variables
		export SYSROOT="$TOOLCHAIN_DIR/sysroot"
		export TOOLCHAIN_BIN_DIR="$TOOLCHAIN_DIR/bin"

		#if NDK version is greater than or equal to 19 and ARCH is not arm
		if [ $NDK_VERSION -ge 19 ] && \
				[ $ARCH != "arm" ]; then
			export C_COMPILER=clang
			export CXX_COMPILER=clang++
			export CPP=
			export CC="$TOOLCHAIN_BIN_DIR/${TOOLCHAIN_COMPILER_PREFIX}${API_LEVEL}-clang"
			export CXX="$TOOLCHAIN_BIN_DIR/${TOOLCHAIN_COMPILER_PREFIX}${API_LEVEL}-clang++"
		#else if NDK version is greater than or equal to 15 and less than 18 and gcc should be used instead of clang
		elif [ $NDK_VERSION -ge 15 ] && \
			[ $NDK_VERSION -lt 18 ] && \
				[ $USE_GCC_INSTEAD_OF_CLANG_UNDER_NDK_VERSION_18 -eq 1 ]; then
			export C_COMPILER=gcc
			export CXX_COMPILER=g++
			export CPP="$TOOLCHAIN_BIN_DIR/$TOOLCHAIN_COMPILER_PREFIX-cpp"
			export CC="$TOOLCHAIN_BIN_DIR/$TOOLCHAIN_COMPILER_PREFIX-gcc"
			export CXX="$TOOLCHAIN_BIN_DIR/$TOOLCHAIN_COMPILER_PREFIX-g++"
		#else if NDK version is greater than or equal to 15
		elif [ $NDK_VERSION -ge 15 ]; then
			export C_COMPILER=clang
			export CXX_COMPILER=clang++
			export CPP=
			export CC="$TOOLCHAIN_BIN_DIR/$TOOLCHAIN_COMPILER_PREFIX-clang"
			export CXX="$TOOLCHAIN_BIN_DIR/$TOOLCHAIN_COMPILER_PREFIX-clang++"
		#else if NDK version is less than 15
		else
			export C_COMPILER=gcc
			export CXX_COMPILER=g++
			export CPP="$TOOLCHAIN_BIN_DIR/$TOOLCHAIN_COMPILER_PREFIX-cpp"
			export CC="$TOOLCHAIN_BIN_DIR/$TOOLCHAIN_COMPILER_PREFIX-gcc"
			export CXX="$TOOLCHAIN_BIN_DIR/$TOOLCHAIN_COMPILER_PREFIX-g++"
		fi

		export LD="$TOOLCHAIN_BIN_DIR/$TOOLCHAIN_BINTOOLS_PREFIX-ld"
		export AR="$TOOLCHAIN_BIN_DIR/$TOOLCHAIN_BINTOOLS_PREFIX-ar"
		export AS="$TOOLCHAIN_BIN_DIR/$TOOLCHAIN_BINTOOLS_PREFIX-as"
		export NM="$TOOLCHAIN_BIN_DIR/$TOOLCHAIN_BINTOOLS_PREFIX-nm"
		export RANLIB="$TOOLCHAIN_BIN_DIR/$TOOLCHAIN_BINTOOLS_PREFIX-ranlib"
		export STRIP="$TOOLCHAIN_BIN_DIR/$TOOLCHAIN_BINTOOLS_PREFIX-strip"

		#validate the current toolchain setup
		toolchain_validation
		if [ $? -ne 0 ]; then
			echo "Toolchain validation failed for TOOLCHAIN=$TOOLCHAIN_PREFIX and API_LEVEL=$API_LEVEL"
			exit 1
		fi
	fi

	#if only toolchains need to be built, then just continue to next loop
	if [ $ONLY_BUILD_TOOLCHAINS -eq 1 ]; then
		continue
	fi

	#for all PROJECT_DIRs in the BUILD_DIR
	for PROJECT_DIR in "$BUILD_DIR"/*; do

		#if not a directory, then skip
		if [ ! -d "$PROJECT_DIR" ]; then
			continue
		fi

		#get PROJECT from basename of PROJECT_DIR
		export PROJECT="$(basename "$PROJECT_DIR")"

		echo -e "\n\n\n\n\n"
		echo "Processing $PROJECT"

		#if PROJECT is not defined in the PROJECTS_TO_BUILD, then skip
		if [[ ! "$PROJECTS_TO_BUILD" =~ (^|[[:space:]])"$PROJECT"($|[[:space:]]) ]]; then
			echo "Skipping build for $PROJECT"
			continue
		fi
	
		echo "Building $PROJECT for $ARCH_SRC"

		#cd to BUILD_DIR
		cd "$BUILD_DIR"

		#check if BUILD_FILE exists in root of PROJECT directory
		BUILD_FILE="$BUILD_DIR/$PROJECT/$BUILD_FILE_NAME"
		if [ ! -f "$BUILD_FILE" ]; then
			echo "$BUILD_FILE not found"
			exit 1
		fi

		#cd to PROJECT directory before running build file
		cd "$PROJECT"

		echo "Running $BUILD_FILE"

		#run BUILD_FILE
		if [ $REDIRECT_BUILD_AND_POST_BUILD_OUTPUT_TO_LOG_FILE -eq 1 ]; then
			echo -e "\n\n\n\n\n" &>> "$BUILD_AND_POST_BUILD_LOG_FILE"
			echo "Building $PROJECT for $ARCH_SRC" &>> "$BUILD_AND_POST_BUILD_LOG_FILE"
			bash "$BUILD_FILE" "$@" &>> "$BUILD_AND_POST_BUILD_LOG_FILE"
		else
			bash "$BUILD_FILE" "$@"
		fi
		return_value=$?
		#if BUILD_FILE exited with a non catastrophic failure like an unsupported action, then continue to next loop
		if [ $return_value -eq $UNSUPPORTED_ARCH_SRC_EXIT_CODE ] || \
			[ $return_value -eq $UNSUPPORTED_C_COMPILER_EXIT_CODE ] || \
				[ $return_value -eq $UNSUPPORTED_CXX_COMPILER_EXIT_CODE ]; then
			echo "$BUILD_FILE for $PROJECT returned that build is unsupported with the current configuration"
			echo "Skipping build"
			continue
		#else if any other failure
		elif [ $return_value -ne 0 ]; then
			echo "Failure while running $BUILD_FILE for $PROJECT for $ARCH_SRC"
			exit 1
		fi

		if [ $REDIRECT_BUILD_AND_POST_BUILD_OUTPUT_TO_LOG_FILE -eq 1 ]; then
			echo "Building $PROJECT for $ARCH_SRC complete" &>> "$BUILD_AND_POST_BUILD_LOG_FILE"
		fi

		echo "Building $PROJECT for $ARCH_SRC complete"

	done

	#remove temp toolchain if needed
	cleanup
	CREATING_TEMP_TOOLCHAIN=0

done

#if only toolchains need to be built, then just exit
if [ $ONLY_BUILD_TOOLCHAINS -eq 1 ]; then
	exit
fi


#if post build scripts need to run
if [ $RUN_POST_BUILD_SCRIPTS -eq 1 ]; then

	#for all POST_BUILD_SCRIPT_FILEs in the POST_BUILD_SCRIPTS_DIR
	for POST_BUILD_SCRIPT_FILE in "$POST_BUILD_SCRIPTS_DIR"/*; do
		
		#if not a file, then skip
		if [ ! -f "$POST_BUILD_SCRIPT_FILE" ]; then
			continue
		fi

		#get POST_BUILD_SCRIPT from basename of POST_BUILD_SCRIPT_FILE
		POST_BUILD_SCRIPT="$(basename "$POST_BUILD_SCRIPT_FILE")"

		echo -e "\n\n\n\n\n"
		echo "Processing $POST_BUILD_SCRIPT"

		#if POST_BUILD_SCRIPT is not defined in the POST_BUILD_SCRIPTS_TO_RUN, then skip
		if [[ ! "$POST_BUILD_SCRIPTS_TO_RUN" =~ (^|[[:space:]])"$POST_BUILD_SCRIPT"($|[[:space:]]) ]]; then
			echo "Skipping run for $POST_BUILD_SCRIPT"
			continue
		fi

		#cd to POST_BUILD_SCRIPTS_DIR before running script
		cd "$POST_BUILD_SCRIPTS_DIR"

		echo "Running $POST_BUILD_SCRIPT"

		#run POST_BUILD_SCRIPT
		if [ $REDIRECT_BUILD_AND_POST_BUILD_OUTPUT_TO_LOG_FILE -eq 1 ]; then
			echo -e "\n\n\n\n\n"
			echo "Processing $POST_BUILD_SCRIPT"
			bash "$POST_BUILD_SCRIPT" "$@" &>> "$BUILD_AND_POST_BUILD_LOG_FILE"
		else
			bash "$POST_BUILD_SCRIPT" "$@"
		fi

		if [ $? -ne 0 ]; then
			echo "Failure while running $POST_BUILD_SCRIPT_FILE"
			exit 1
		fi

		if [ $REDIRECT_BUILD_AND_POST_BUILD_OUTPUT_TO_LOG_FILE -eq 1 ]; then
			echo "$POST_BUILD_SCRIPT run complete" &>> "$BUILD_AND_POST_BUILD_LOG_FILE"
		fi

		echo "$POST_BUILD_SCRIPT run complete"
	done

fi

#if projects were copied to BUILD_DIR and if BUILD_DIR needs to removed after building
if [ $COPY_PROJECTS_TO_BUILD_DIR_BEFORE_BUILDING -eq 1 ] && \
	[ $REMOVE_BUILD_DIR_AFTER_BUILDING -eq 1 ] && \
		[ ! -z "$ORIGINAL_BUILD_DIR" ]; then
		echo -e "\n\n\n\n\n"
		echo "Removing $ORIGINAL_BUILD_DIR"
		rm -rf "$ORIGINAL_BUILD_DIR"
		if [ $? -ne 0 ]; then
			echo "Failed"
			exit 1
		fi
fi

echo -e "\n\nAll done"

