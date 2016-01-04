#!/bin/sh -e

cat <<EOF

Welcome to the Maru installer!

Before getting started, please ensure your Nexus 5 is connected
to your computer.

IMPORTANT: Installing Maru requires a factory reset of your device
so make sure you first back-up any important data!

EOF

mecho () {
    # use /bin/echo for portability with the '-n' option on Macs
    if [ $# -gt 1 ] ; then
        /bin/echo "$1" "--> $2"
    else
        /bin/echo "--> $1"
    fi
}

fatal () {
    cat <<EOF

    Yikes, something went wrong with the installation. We're sorry.

    Please contact us at hello@maruos.com with the issue you are facing
    and we'll personally walk you through the install process.

EOF
    exit 1
}

start () {
    check_zip
}

missing_tools () {
    cat <<EOF

Woops, you're missing some tools to flash Maru on your device.

If you're on Debian or Ubuntu, install 'android-tools-adb'
and 'android-tools-fastboot'. You can do it in your package manager
or on the terminal:

    $ sudo apt-get install android-tools-adb android-tools-fastboot

If your system doesn't have the above packages you can install the
Android stand-alone SDK tools from below:

    http://developer.android.com/sdk/index.html#Other

Please run this installer again when you're done.

EOF
}

check_tools () {
    mecho -n "Sweet. Let's make sure you have the right tools to install Maru..."
    if [ ! -f "$(which adb)" ] ; then
        mecho "Can't find 'adb'"
        missing_tools
        exit 1
    fi

    if [ ! -f "$(which fastboot)" ] ; then
        mecho "Can't find 'fastboot'"
        missing_tools
        exit 1
    fi
    echo "OK"

    check_zip
}

check_zip () {
    mecho -n "Checking for a complete installation zip..."
    if [ ! -f boot.img ] || [ ! -f system.img ] || [ ! -f userdata.img ] ; then
        echo "ERROR"
        cat <<EOF

    Hmm, looks like your installer is a missing a few things.

    Are you running this install script outside the directory you
    unzipped Maru in?

    If that isn't it, please try downloading the installer zip again.

EOF
        exit 1
    fi
    echo "OK"

    reboot_recovery
}

check_recovery () {
    mecho -n "Checking that your device is in recovery mode..."
    if [ "$(./fastboot devices | wc -l)" -eq 0 ] ; then
        echo "ERROR"
        return 1
    fi
    echo "OK"
    return 0
}

reboot_recovery () {
    if check_recovery ; then
        flash
    fi

    mecho -n "Rebooting your device into recovery mode..."
    if ! ./adb reboot bootloader >/dev/null 2>&1 ; then
        echo "ERROR"
        cat <<EOF

    Looks like your device isn't connected or you don't have USB debugging enabled.

    If you device is connected, please ensure USB debugging is enabled on your device:

        (1) Go to the Settings app and scroll down to the System section

            (If you already have "Developer options" under System then go
             directly to (5))

        (2) Tap on "About phone"
        (3) Tap "Build number" 7 times until you get a message that says
            you are now a developer
        (4) Go back to the main Settings app
        (5) Tap on "Developer options"
        (6) Ensure that "USB debugging" is enabled

EOF
        mecho -n "Did you manage to connect your phone and enable USB debugging? (yes/no): "
        read response

        if [ "$response" = "yes" ] ; then
            mecho -n "Great! Trying one more time..."
            if ./adb reboot bootloader >/dev/null 2>&1 ; then
                echo "OK"
                flash
            else
                echo "ERROR"
            fi
        fi

        reboot_recovery_manual

        exit 1
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

flash () {
    mecho -n "Checking bootloader lock state..."
    local unlock_state="$(./fastboot oem device-info 2>&1 | grep -i "unlocked" | cut -f 4 -d " ")"
    if [ "$unlock_state" = "false" ] ; then
        echo "LOCKED"
        unlock_bootloader
    else
        echo "UNLOCKED"
    fi

    # echo "BAIL!"
    # exit 1

    # point of no return!
    mecho "Installing Maru, please keep your device connected..."
    ./fastboot format cache
    ./fastboot flash boot boot.img
    ./fastboot flash system system.img
    ./fastboot flash userdata userdata.img

    mecho "Done!"

    mecho "Rebooting into Maru..."
    ./fastboot reboot >/dev/null 2>&1

    exit 0
}

mecho -n "Are you ready to install Maru? (yes/no): "
read response

if [ "$response" != "yes" ] ; then
    mecho "Aborting installation."
    exit 0
fi

start
