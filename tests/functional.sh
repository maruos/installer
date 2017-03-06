#!/bin/bash

#
# Copyright 2017 The Maru OS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -u

readonly SCRIPT_DIR="$(dirname "$0")"
source "${SCRIPT_DIR}/test.sh"

# keep in sync with install.sh
readonly SUCCESS=0
readonly SUCCESS_BASE=$(( 1 << 5 ))
readonly ERROR_BASE=$(( 1 << 6 ))
readonly SUCCESS_USER_ABORT=$(( SUCCESS_BASE + 1 ))
readonly SUCCESS_BOOTLOADER_UNLOCKED=$(( SUCCESS_BASE + 2 ))
readonly ERROR_INCOMPLETE_ZIP=$(( ERROR_BASE + 1 ))
readonly ERROR_ADB=$(( ERROR_BASE + 2 ))
readonly ERROR_FASTBOOT_PERMS=$(( ERROR_BASE + 3 ))
readonly ERROR_INCORRECT_INSTALLER=$(( ERROR_BASE + 4 ))

mock_fastboot () {
    local readonly in_bootloader="$1"
    local readonly product="$2"
    local readonly lock_state="$3"

    local unlocked="false"
    if [ "$lock_state" = "unlocked" ] ; then
        unlocked="true"
    fi

    cat >fastboot <<EOF
#!/bin/bash

echo_oem_device_info () {
    cat <<_EOF
...
(bootloader) 	Device tampered: true
(bootloader) 	Device unlocked: $unlocked
(bootloader) 	off-mode-charge: true
OKAY [  0.003s]
finished. total time: 0.003s
_EOF
}

echo_oem_device_info_flo () {
    # flo always reports false even when unlocked
    cat <<_EOF
...
(bootloader)     Device tampered: false
(bootloader)     Device unlocked: false
(bootloader)     SB=Y
OKAY [  0.004s]
finished. total time: 0.004s
_EOF
}

echo_getvar_lock_state () {
    # assume generic devices don't have lock_state var
    cat <<_EOF
lock_state:
finished. total time: 0.000s
_EOF
}

echo_getvar_lock_state_flo () {
    cat <<_EOF
lock_state: $lock_state
finished. total time: 0.000s
_EOF
}

case "\$*" in
    "devices")
        if [ "$in_bootloader" = "true" ] ; then
            echo "06d123d34ffdf166	fastboot"
        fi
        exit 0
        ;;
    "getvar product")
        echo "product: $product"
        exit 0
        ;;
    "oem device-info")
        if [ "$product" = "flo" ] ; then
            echo_oem_device_info_flo
        else
            echo_oem_device_info
        fi
        exit 0
        ;;
    "getvar lock_state")
        if [ "$product" = "flo" ] ; then
            echo_getvar_lock_state_flo
        else
            echo_getvar_lock_state
        fi
        exit 0
        ;;
esac

case "\$1" in
    format|flash|reboot|oem)
        exit 0
        ;;
    *)
        echo "usage: fastboot ... "
        echo "unknown command: \$*"
        exit 1
        ;;
esac
EOF
    chmod +x fastboot
}

mock_adb () {
    cat >adb <<EOF
#!/bin/bash

if [ "\$*" = "reboot bootloader" ] ; then
    exit 0
fi

exit 1
EOF
    chmod +x adb
}

mock_android-info () {
    local readonly board="$1"
    echo "require board=$board" > android-info.txt
}

setup () {
    : > boot.img
    : > system.img
    mock_adb
}

teardown () {
    {
        rm boot.img
        rm system.img
        rm adb
        rm fastboot
        rm android-info.txt
    } &>/dev/null
}

trap teardown EXIT

echo "Installer should..."
echo

techo "abort if user answers 'no' to prompt"
echo "no" | ./install.sh >/dev/null
tassert_eq $SUCCESS_USER_ABORT $?

techo "abort if missing a complete zip"
echo "yes" | ./install.sh >/dev/null
tassert_eq $ERROR_INCOMPLETE_ZIP $?

setup

techo "abort if incorrect installer for device"
mock_fastboot "true" "hammerhead" "locked"
mock_android-info "fakedevice"
echo "yes" | ./install.sh >/dev/null
tassert_eq $ERROR_INCORRECT_INSTALLER $?

techo "unlock a locked flo"
mock_fastboot "true" "flo" "locked"
mock_android-info "flo"
echo "yes" | ./install.sh >/dev/null
tassert_eq $SUCCESS_BOOTLOADER_UNLOCKED $?

techo "unlock a generic locked device"
mock_fastboot "true" "hammerhead" "locked"
mock_android-info "hammerhead"
echo "yes" | ./install.sh >/dev/null
tassert_eq $SUCCESS_BOOTLOADER_UNLOCKED $?

techo "install succesfully on unlocked flo with workaround"
mock_fastboot "true" "flo" "unlocked"
mock_android-info "flo"
echo "yes" | ./install.sh >/dev/null
tassert_eq $SUCCESS $?

techo "install succesfully on a generic unlocked device"
mock_fastboot "true" "hammerhead" "unlocked"
mock_android-info "hammerhead"
echo "yes" | ./install.sh >/dev/null
tassert_eq $SUCCESS $?

texit
