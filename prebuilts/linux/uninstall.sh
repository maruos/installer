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

Welcome to the Maru Uninstaller.

This script will ease the process of restoring your device
to factory settings.

Before getting started, you will need to:

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

WARNING: Uninstalling Maru will wipe all your personal data
so make sure you first back-up anything important!

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

    1. Please download your device's factory image for the Android version you want:

        https://developers.google.com/android/images

    2. Unzip the factory image archive (change the name to match the image you downloaded):

        $ unzip hammerhead-m4b30z-factory-625c027b.zip

    3. Copy-paste the full path to the extracted directory below.
       It should look something like:

        /home/USER/Downloads/hammerhead-m4b30z

EOF

mecho -n "Please enter the full path to the factory image directory: "
read factory_dir

export PATH="$SCRIPT_PATH":"$PATH"

cd "$factory_dir"

mecho "Restoring your device to factory settings..."
adb reboot bootloader
sleep 7
./flash-all.sh

mecho "Done!"
mexit 0
