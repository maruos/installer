#!/bin/bash -e

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

cat <<EOF

Welcome to the Maru installer!

In order to install Maru you will need to:

1. Connect your Nexus 5 to your computer over USB

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
    if [ $# -gt 1 ] ; then
        /bin/echo "$1" "$2"
    else
        /bin/echo "$1"
    fi
}

mexit () {
    cd - >/dev/null 2>&1
    exit $1
}

fatal () {
    cat <<EOF

    Yikes, something went wrong with the installation. We're sorry.

    Please contact us at hello@maruos.com with the issue you are facing
    and we'll personally walk you through the install process.

EOF
    mexit 1
}

start () {
    check_zip
}

echo_incomplete_zip () {
    cat <<EOF

Hmm, looks like your installer is a missing a few things.

Are you running this install script outside the directory you
unzipped Maru in?

If that isn't it, please try downloading the installer again.

EOF
}

check_zip () {
    mecho -n "Checking for a complete installation zip..."
    if [ ! -f boot.img ] || [ ! -f system.img ] ; then
        echo "ERROR"
        echo_incomplete_zip
        mexit 1
    fi
    echo "OK"

    reboot_recovery
}

echo_permissions_udev () {
    cat <<EOF

On certain Linux distributions (Ubuntu 14.04 for example),
you will need to explicitly add permissions to access USB devices:

1. Disconnect your device from USB

2. Run this in a terminal (requires sudo):

    $ wget -q -O - http://source.android.com/source/51-android.rules | sed "s/<username>/$USER/" | sudo tee /etc/udev/rules.d/51-android.rules; sudo udevadm control --reload-rules

3. Re-connect your device over USB and re-run this installer

EOF
}

check_fastboot () {
    if [ "$(./fastboot devices | cut -f 1)" = "no permissions" ] ; then
        return 1
    fi
    return 0
}

check_recovery () {
    mecho -n "Checking whether your device is in recovery mode..."
    if [ "$(./fastboot devices | wc -l)" -eq 0 ] ; then
        echo ""
        return 1
    fi
    echo "OK"
    return 0
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

reboot_recovery () {
    if check_recovery ; then
        flash
    fi

    mecho -n "Rebooting your device into recovery mode..."
    if ! ./adb reboot bootloader >/dev/null 2>&1 ; then
        echo "ERROR"
        echo_device_not_found
        mexit 1
    fi
    echo "OK"

    sleep 7
    if ! check_recovery ; then
        fatal
    fi
    flash
}

reboot_recovery_manual () {
    cat <<EOF

    OK, let's do this the manual way:

    (1) Power off your device
    (2) Boot into recovery by holding down the Volume Up,
        Volume Down, and Power buttons on your device for a couple of seconds

EOF

    mecho -n "Hit [ENTER] when your device has rebooted into recovery mode: "
    read response


    if ! check_recovery ; then
        fatal
    fi
    flash
}

unlock_bootloader () {
    mecho -n "Unlocking bootloader, you will need to confirm this on your device..."
    if ! ./fastboot oem unlock >/dev/null 2>&1 ; then
        echo "ERROR"
        fatal
    fi
    echo "OK"
}

echo_unlock_reboot () {
    cat <<EOF

Successfully unlocked bootloader!

Your device will need to reboot before continuing. It will factory
reset, so this reboot can take a few minutes longer than usual.

Please re-run this script after your device completely boots up
and you have re-enabled USB Debugging.

EOF
}

echo_success () {
    cat <<EOF

The first boot will take 2-3 mins as Maru sets up
your device so please be patient.

Rebooting into Maru...
EOF
}

flash () {
    mecho -n "Checking bootloader lock state..."

    if ! check_fastboot ; then
        echo "ERROR"
        echo_permissions_udev
        mexit 1
    fi

    local unlock_state="$(./fastboot oem device-info 2>&1 | grep -i "unlocked" | cut -f 4 -d " ")"
    if [ "$unlock_state" = "false" ] ; then
        echo "LOCKED"
        unlock_bootloader
        echo_unlock_reboot
        ./fastboot reboot >/dev/null 2>&1
        mexit 0
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
    ./fastboot format userdata

    mecho
    mecho "Installation complete!"

    echo_success
    ./fastboot reboot >/dev/null 2>&1

    mexit 0
}

# enforce same directory as script
# this allows double-clicking the script to work on mac
cd "$(dirname "$0")"

mecho -n "Are you ready to install Maru? (yes/no): "
read response
mecho

if [ "$response" != "yes" ] ; then
    mecho "Aborting installation."
    exit 0
fi

start
