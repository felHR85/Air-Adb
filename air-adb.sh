#!/bin/bash

# OS dependant constants
OSX_ADB_DEFAULT_PATH=/Applications/AndroidSDK/sdk/platform-tools/adb
LINUX_ADB_DEFAULT_PATH=~/Android/Sdk/platform-tools/adb

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
set -e
ADB_PATH=$(which adb)

if [[ -x $ADB_PATH ]]; then
    ADB="adb"
else
    ADB=$(getAdbPath)
    if [[ ! -x $ADB ]]; then
        echo "air-adb: adb not found in $ADB"
        exit 1
    fi
fi

# Restart adb
$ADB kill-server && $ADB start-server

# Get ip of your mobile device trying different methods if necessary
IP=$(getIP1 $ADB)
if [[ -z $IP ]]; then
    IP=$(getIP2 $ADB)
    if [[ -z $IP ]]; then
        IP=$(getIP3 $ADB)
        if [[ -z $IP ]]; then
            echo "air-adb: couldn't get any ip directly from the device"
            exit -1
        fi
    fi
fi

#Validated IP
VALID_IP=$(echo $IP | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")
if [[ -z $VALID_IP ]]; then
    echo "air-adb: $IP invalid ip address"
    exit 1
fi

# Adb stuff
#TODO stop execution when something wrong
echo $($ADB tcpip $PORT)
echo $($ADB connect $VALID_IP)
MODEL=$($ADB devices -l | grep $VALID_IP | awk '{print $4}' | awk -F ':' '{print $2}')
echo "adb-air: $MODEL connected with ip: $VALID_IP, port: $PORT"
exit 0

