#!/bin/sh -e
#
# Copyright (c) 2015 Maru
#

cat <<EOF

Welcome to the Maru Uninstaller.

This script will ease the process of restoring your device
to factory settings.

Before getting started, you will need to:

1. Connect your Nexus 5 to your computer over USB

2. Enable USB Debugging on your device:

    1)  Go to the Settings app and scroll down to
        the System section

        NOTE: If you already have "Developer options" under
        System then go directly to #5

    2)  Tap on "About phone"
    3)  Tap "Build number" 7 times until you get a message that says
        you are now a developer
    4)  Go back to the main Settings app
    5)  Tap on "Developer options"
    6)  Ensure that "USB debugging" is enabled

IMPORTANT: Please make sure you back-up any important data
before proceeding!

EOF

mecho () {
    # use /bin/echo for portability with the '-n' option on Macs
    if [ $# -gt 1 ] ; then
        /bin/echo "$1" "--> $2"
    else
        /bin/echo "--> $1"
    fi
}

mexit () {
    cd - >/dev/null 2>&1
    exit $1
}

SCRIPT_PATH="$(cd "$(dirname "$0")" ; pwd)"

mecho -n "Are you ready to uninstall Maru? (yes/no): "
read response

if [ "$response" != "yes" ] ; then
    mecho "Aborting uninstall."
    exit 0
fi

cat <<EOF

    1. Please download the factory image for the Android version you want:

        https://developers.google.com/android/nexus/images?hl=en#hammerhead

    2. Unzip the factory image

    3. Copy-paste the full path to the unzipped directory when prompted.
       It should look something like:

        /home/USER/Downloads/hammerhead-lmy48m

EOF

mecho -n "Full path to unzipped factory image directory: "
read factory_dir

export PATH="$SCRIPT_PATH":"$PATH"

cd "$factory_dir"

mecho "Restoring your device to factory settings..."
adb reboot bootloader
sleep 7
./flash-all.sh

mecho "Done!"
mexit 0
