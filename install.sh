#!/bin/bash

#
# Copyright 2015-2016 Preetam J. D'Souza
# Copyright 2016 The Maru OS Project
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

set -e
set -u

readonly SUCCESS=0
readonly SUCCESS_BASE=$(( 1 << 5 ))
readonly ERROR_BASE=$(( 1 << 6 ))
readonly SUCCESS_USER_ABORT=$(( SUCCESS_BASE + 1 ))
readonly SUCCESS_BOOTLOADER_UNLOCKED=$(( SUCCESS_BASE + 2 ))
readonly ERROR_INCOMPLETE_ZIP=$(( ERROR_BASE + 1 ))
readonly ERROR_ADB=$(( ERROR_BASE + 2 ))
readonly ERROR_FASTBOOT_PERMS=$(( ERROR_BASE + 3 ))
readonly ERROR_INCORRECT_INSTALLER=$(( ERROR_BASE + 4 ))

cat <<EOF

Welcome to the Maru installer!

In order to install Maru you will need to:

1. Connect your device to your computer over USB

2. Enable USB Debugging on your device:

    1)  Go to the Settings app and scroll down to
        the System section

        NOTE: If you already have "Developer options"
        under System then go directly to #5

    2)  Tap on "About phone"
    3)  Tap "Build number" 7 times until you get a message
        that says you are now a developer
    4)  Go back to the main Settings app
    5)  Tap on "Developer options"
    6)  Ensure that "USB debugging" is enabled
    7)  Tap "OK" if you see a dialog asking you to allow
        USB Debugging for your computer's RSA key fingerprint

WARNING: Installing Maru will wipe all your personal data
so make sure you first back-up anything important!

EOF

mecho () {
    # use /bin/echo for portability with the '-n' option on Macs
    /bin/echo "$@"
}

mexit () {
    cd - >/dev/null 2>&1
    exit $1
}

fatal () {
    cat <<EOF

Yikes, something went wrong with the installation. We're sorry.

Please contact us at hello@maruos.com with the issue you are facing and we'll
personally walk you through the install process.

EOF
    mexit 1
}

echo_incomplete_zip () {
    cat <<EOF

Hmm, looks like your installer is a missing a few things.

Are you running this install script outside the directory you unzipped Maru in?

If that isn't it, please try downloading the installer again.

EOF
}

echo_device_not_found () {
    cat <<EOF

Hmm, your device can't be found.

Please ensure that:

1. Your device is connected to your computer over USB
2. You have USB Debugging enabled (see above for instructions)
3. You unlock your device and tap "OK" if you see a dialog asking you
   to allow USB Debugging for your computer's RSA key fingerprint

Go ahead and re-run the installer when you're ready.

EOF
}

echo_permissions_udev () {
    cat <<EOF

On certain Linux distributions (Ubuntu 14.04 for example),
you will need to explicitly add permissions to access USB devices:

1. Disconnect your device from USB

2. Run this in a terminal (requires sudo):

    $ wget -S -O - https://github.com/snowdream/51-android/blob/master/51-android.rules | sed "s/<username>/$USER/" | sudo tee >/dev/null /etc/udev/rules.d/51-android.rules; sudo udevadm control --reload-rules

3. Re-connect your device over USB and re-run this installer

EOF
}

echo_incorrect_installer() {
    local readonly product="$1"
    cat <<EOF

Woops, looks like you are using the wrong installer for your device!

Please download the correct installer, making sure that your device codename
($product) is listed in the zip file name.

EOF
}

echo_unlock_reboot () {
    cat <<EOF

Successfully unlocked bootloader!

Your device will need to reboot before continuing. It will factory reset, so
this reboot can take a few minutes longer than usual.

Please re-run this script after your device completely boots up and you have
re-enabled USB Debugging.

EOF
}

echo_success () {
    cat <<EOF

The first boot will take 2-3 mins as Maru sets up your device so please be
patient.

Rebooting into Maru...
EOF
}

check_fastboot () {
    if [ "$(./fastboot devices | cut -f 1)" = "no permissions" ] ; then
        return 1
    fi
    return 0
}

check_is_bootloader () {
    if [ "$(./fastboot devices | wc -l)" -eq 0 ] ; then
        return 1
    fi
    return 0
}

fastboot_get_product () {
    echo "$(./fastboot getvar product 2>&1 | grep -i "product" | cut -f 2 -d " ")"
}

fastboot_get_lock_state_generic () {
    local readonly unlocked="$(./fastboot oem device-info 2>&1 | grep -i "device unlocked" | cut -f 4 -d " ")"
    if [ "$unlocked" = true ] ; then
        echo "unlocked"
    else
        echo "locked"
    fi
}

fastboot_get_lock_state () {
    local readonly product="$1"
    case "$product" in
        # flo is weird and shows incorrect lock state in oem device-info, so use this workaround
        flo) echo "$(./fastboot getvar lock_state 2>&1 | uniq | grep -i "lock_state" | cut -f 2 -d " ")" ;;
        *) echo "$(fastboot_get_lock_state_generic)" ;;
    esac
}

unlock_bootloader () {
    mecho -n "Unlocking bootloader, you will need to confirm this on your device..."
    if ! ./fastboot oem unlock >/dev/null 2>&1 ; then
        echo "ERROR"
        fatal
    fi
    echo "OK"
}

main () { # avoid global namespace for local variables

# enforce same directory as script
# this allows double-clicking the script to work on mac
cd "$(dirname "$0")"

mecho -n "Are you ready to install Maru? (yes/no): "
read response
mecho
if [ "$response" != "yes" ] ; then
    mecho "Aborting installation."
    mexit $SUCCESS_USER_ABORT
fi

mecho -n "Checking for a complete installation zip..."
if [ ! -f android-info.txt ] || [ ! -f boot.img ] || [ ! -f system.img ] ; then
    echo "ERROR"
    echo_incomplete_zip
    mexit $ERROR_INCOMPLETE_ZIP
fi
echo "OK"


if ! check_is_bootloader ; then
    mecho -n "Rebooting your device into bootloader..."
    ./adb reboot bootloader >/dev/null 2>&1 || {
        echo "ERROR"
        echo_device_not_found
        mexit $ERROR_ADB
    }
    echo "OK"

    # wait for the device to reboot into bootloader
    sleep 7
fi

if ! check_is_bootloader ; then
    fatal
fi


if ! check_fastboot ; then
    echo "ERROR"
    echo_permissions_udev
    mexit $ERROR_FASTBOOT_PERMS
fi

mecho -n "Checking that this is the correct installer for your device..."
local readonly product="$(fastboot_get_product)"
if ! grep "$product" < android-info.txt &>/dev/null ; then
    echo "ERROR"
    echo_incorrect_installer "$product"
    mexit $ERROR_INCORRECT_INSTALLER
fi
echo "OK"

mecho -n "Checking bootloader lock state..."
local readonly lock_state="$(fastboot_get_lock_state "$product")"
if [ "$lock_state" = locked ] ; then
    echo "LOCKED"
    unlock_bootloader
    echo_unlock_reboot
    ./fastboot reboot >/dev/null 2>&1
    mexit $SUCCESS_BOOTLOADER_UNLOCKED
else
    echo "UNLOCKED"
fi

# echo "BAIL!"
# mexit 1

# point of no return!
mecho
mecho "Installing Maru, please keep your device connected..."
./fastboot format cache
./fastboot flash boot boot.img
./fastboot flash system system.img
if [ ! -f userdata.img ] ; then
    ./fastboot format userdata
else
    ./fastboot flash userdata userdata.img -w
fi

mecho
mecho "Installation complete!"

echo_success
./fastboot reboot >/dev/null 2>&1

mexit $SUCCESS

}

main
