# Android NDK Cross Compile Build Automator

An overlay build system to easily mass cross compile autoconf based projects for Android using the NDK for any target arch and API level. 



## How This Works:

You supply it with path to an Android NDK. Any NDK version can be used (or atleast as far back as r10e atleast). You place projects you want to build in the projects directory. You modify/add any archs and API levels you want to build for by modifying/adding arch source files in the archs directory. You create a custom build file in the root of each project to be built that contains the relevant configure, make and make install commands. Additional custom scripts can placed in the post_build_scripts to extract the required binaries/libraries from the install directory after all builds are complete.
Then simply run the android_ndk_cross_compile_build_automator.sh script and it will automatically build the toolchains for each arch source file and API level set and then call the build file for each project after exporting the relevant compiler, bintools, target arch, API level and some other variables. The build file can update any additional project specific flags like CFLAGS, CXXFLAGS, LDFLAGS or any other flags or parameters and can call the relevant configure, make and make install commands to build the project. After builds of all projects of all arch source files are complete, then post build scripts can be run to process the built files.


## Usage Guide:

- Install dependencies:
	The following instructions are for Ubuntu. Will differ on other platforms. This project requires bash.
	`sudo apt update`
	
	If you want to build autoconf based projects:
	`sudo apt install autoconf automake libtool`
	

- Download Latest `Android NDK` from [here](https://developer.android.com/ndk/downloads) or an older version from [here](https://developer.android.com/ndk/downloads/older_releases). Extract it to a directory. Default is`$HOME/Android/ndk/`.
- Download a `Android NDK Cross Compile Build Automator` release from [here](). Extract it in any directory.
- The directory structure by default should be something like this:
```
- android_ndk_cross_compile_build_automator
	- config/
		- archs/
			- ARCH_SRC files...
	- install/
	- out/
	- post_build_scripts/
	- projects/
	- tools/
	- templates/
		- android_ndk_cross_compile_build.sh
	- android_ndk_cross_compile_build_automator.sh
```

- Open the `android_ndk_cross_compile_build_automator.sh` file and read the `USER MODIFIABLE VARIABLES` section. It defines important variables and what they all do. They are too long to write here.


- Open the config/archs directory and look over the arch source files. This project refers to the archs directory as `ARCHS_DIR` and any files in it as `ARCH_SRC`. Each `ARCH_SRC` is sourced to define variables that contain information on which toolchain to build and to set any general compiler/linker flags needed to build for that `ARCH_SRC`. This project already has the following `ARCH_SRC` files that can be used as templates: `armeabi-android4.0.4- armeabi armeabi-v7a arm64-v8a x86 x86-64`. The `armeabi-android4.0.4-` is a special `ARCH_SRC` added which is the same as armeabi other than `API_LEVEL` and can be used at runtime by projects to build separate binaries/libraries with and without `PIE/PIC` flags or to build for lower API levels than armeabi. Check the `android_ndk_cross_compile_build.sh` template files for more info. 
The following variables are defined by default in the existing `ARCH_SRC` files:
	- `ARCH` defines the arch for which the toolchain should be built to build projects for that ARCH. The archs that are supported are: `arm armv7a arm64 x86 x86_64 mips mips64 mips32r6`. `armv7a` is specially added to fix some edge cases and does not exist as an arch in the Android NDK, but if it is specified, the toolchain built will be the same as `arm`.
	- `API_LEVEL` is the minimum API level you want to target for which toolchains should be built for. This is the same as `minSdkVersion` or `ANDROID_PLATFORM`.
	- `CFLAGS` defines the target arch specific c compiler flags passed to `clang/gcc` while building every project.
	- `CXXFLAGS` defines the target arch specific c++ compiler flags passed to `clang++/g++` while building every project.
	- `LDFLAGS` defines the target arch specific linker flags passed to `ld` while building every project.
Set the variable values according to your needs.


- Place any projects you want to build in the projects directory. This project refers to the projects directory as `PROJECTS_DIR` and any directories in it as `PROJECT`.


- Now copy the `templates/android_ndk_cross_compile_build.sh` to the root of each project directory. This project refers to this build file as `BUILD_FILE`. The directory structure should look like this:
```
- android_ndk_cross_compile_build_automator
	- ...
	- projects/
		- project1
			- android_ndk_cross_compile_build.sh
			- source files of the project1...
		- project2
			- android_ndk_cross_compile_build.sh
			- source files of the project2...
```


- Now modify `android_ndk_cross_compile_build.sh` of each project according to your requirements. Mainly the CPPFLAGS, CFLAGS, CXXFLAGS, LDFLAGS and command options to configure would need to be changed depending on each project. Read the `android_ndk_cross_compile_build.sh`, there is enough info in it to make appropriate changes.


- Now optionally place any post build scripts you want to run after all the builds are complete in the post_build_scripts directory. Post build scripts can be used to extract the needed binaries and executables from the install directory. This project refers to the post_build_scripts directory as `POST_BUILD_SCRIPTS_DIR` and any files in it as `POST_BUILD_SCRIPT`.


- Then open `android_ndk_cross_compile_build_automator.sh`.


- Then modify the value of `ARCHS_SRC_TO_BUILD` and specify the `ARCH_SRC` files in the `ARCHS_DIR` that you want to build the projects for.


- Then modify the value of `PROJECTS_TO_BUILD` and specify the `PROJECT`s in the `PROJECTS_DIR` that you want to build.


- Then modify the value of `POST_BUILD_SCRIPTS_TO_RUN` and specify the `POST_BUILD_SCRIPT`s in the `POST_BUILD_SCRIPTS_DIR` that you want to run after builds are complete.


- Then modify `ANDROID_NDK_ROOT`, `TOOLCHAIN_DIR_PREFIX` and other variables that need changing.


- Finally run the command `bash android_ndk_cross_compile_build_automator.sh` to start the build process.


- The `android_ndk_cross_compile_build_automator.sh` will process all `ARCH_SRC`s files set in `ARCHS_SRC_TO_BUILD` one by one. It will fist create a toolchain for the `ARCH_SRC` being processed if it does not exist or it may use a prebuilt one, then run all `BUILD_FILE`s of all projects set in `PROJECTS_TO_BUILD` one by one. Then move to the next `ARCH_SRC` and build toolchain and projects for it and so on and so forth. Then it will run all `POST_BUILD_SCRIPT`s files set in `POST_BUILD_SCRIPTS_TO_RUN`.


- Any parameters passed to `android_ndk_cross_compile_build_automator.sh` will also be passed to all `BUILD_FILE`s of all projects and all post build scripts. Moreover any CPPFLAGS, CFLAGS, CXXFLAGS, LDFLAGS that were set before this command is run will also be exported to `BUILD_FILE`s of all projects along with the flags set by the `ARCH_SRC` file being processed.


- Depending on you make commands the install directory should contain the files built. This project refers to the install directory as `INSTALL_DIR`. If you are using the same DESTDIR for the make install command as in the template then installed files will be at `$INSTALL_DIR/$PROJECT/$ARCH_SRC` for each PROJECT and ARCH_SRC.


Currently tested by building fusermount for android on Ubuntu 16.04 x86_64 with NDK r15c and r20. You can check it out [here](https://github.com/agnostic-apollo/fuse).

Credits:  
[libiconv](https://github.com/palmerc/libiconv)  
[Daniel Pocock](https://danielpocock.com/building-existing-autotools-c-projects-on-android)  
[jorgenpt](https://gist.github.com/jorgenpt/1961404)  

