#!/bin/bash

# OS dependant constants
OSX_ADB_DEFAULT_PATH=/Applications/AndroidSDK/sdk/platform-tools/adb
LINUX_ADB_DEFAULT_PATH=~/Android/Sdk

# Default values
PORT=5555

# Functions
function getAdbPath(){
    OS=$(uname -s)
    case $OS in
        Darwin)
            echo $OSX_ADB_DEFAULT_PATH
        ;;

        Linux)
            echo $LINUX_ADB_DEFAULT_PATH
        ;;

        CYGWIN*|MINGW32*|MSYS*)
            echo WINDOWS_PATH_HERE
        ;;
        
    esac
}

function getIP1() {
    IP=$($1 shell netcfg | grep wlan0 | awk '{print $3}' | cut -d '/' -f 1)
    echo $IP
}

function getIP2() {
    IP=$($1 shell ip addr show wlan0 | grep "inet\s" | awk '{print $2}' | awk -F'/' '{print $1}')
    echo $IP
}

function getIP3() {
    IP=$($1 shell ip route | tail -n 1 | awk '{print $9}')
    echo $IP
}

# Get adb from path or directly from default Android SDK installations
ADB_PATH=$(which adb)

if [[ -x $ADB_PATH ]]; then
    ADB="adb"
else
    ADB=$(getAdbPath)
fi

$ADB kill-server && adb start-server

# Get ip of your mobile device trying different methods if necessary
IP=$(getIP1 $ADB)
if [[ -z $IP ]]; then
    IP=$(getIP2 $ADB)
    if [[ -z $IP ]]; then
        IP=$(getIP3 $ADB)
        if [[ -z $IP ]]; then
            exit -1
        fi
    fi
fi

echo $IP

# Adb stuff
echo $($ADB tcpip $PORT)
echo $($ADB connect $IP)
#TODO: List information
