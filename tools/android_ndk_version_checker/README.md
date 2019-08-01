# Android NDK Version Checker

Usage:

Run `get_ndk_version` and `assert_ndk_version` for full usage guide and also check the scripts themselves.
Also check `test.sh` for examples on how to use the commands in bash scripts.

Get Android NDK full version:
	`get_ndk_version a "$ANDROID_NDK_ROOT"`

Get Android NDK major version:
	`get_ndk_version m "$ANDROID_NDK_ROOT"`

Check if Android NDK version is atleast 19.0.0:
	`assert_ndk_version 19.0.0 "$ANDROID_NDK_ROOT"`


Credits for original scripts:
[jorgenpt](https://gist.github.com/jorgenpt/1961404)



