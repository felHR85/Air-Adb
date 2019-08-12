#!/bin/bash

# Version: 1

# OS dependant constants
OSX_ADB_DEFAULT_PATH=~/Library/Android/sdk/platform-tools/adb
LINUX_ADB_DEFAULT_PATH=~/Android/Sdk/platform-tools/adb

# Default values
PORT=5555
WIN_MOUNTED_UNIT=C:

# Functions
function getAdbPath(){
    OS=$(uname -s)
    case $OS in
        Darwin)
            echo $OSX_ADB_DEFAULT_PATH
        ;;

        Linux)
            HAS_MICROSOFT=$(uname -a | grep Microsoft)
            if [[ -z $HAS_MICROSOFT ]]; then #Linux
                echo $LINUX_ADB_DEFAULT_PATH
            else #Windows subsystem for Linux
                WINDOWS_USER=$(whoami.exe | awk -F "\\" '{print $2}')
                MOUNT_C=$(cat /proc/mounts | grep $WIN_MOUNTED_UNIT | awk '{print $2}')
                echo $MOUNT_C/Users/${WINDOWS_USER/$'\r'/}/AppData/Local/Android/Sdk/platform-tools/adb.exe
            fi
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
    ADB=$ADB_PATH
else
    ADB=$(getAdbPath)
    if [[ ! -x $ADB ]]; then
        echo "air-adb: adb not found in $ADB"
        exit 1
    fi
fi

# Restart adb
IS_WSL=$(uname -a | grep Microsoft)
if [[ -z $IS_WSL ]]; then # Linux/ OSX
    $ADB kill-server && $ADB start-server
else # Windows subsystem for Linux
    # For some reason in WSL1 start-server doesnt terminate. A sigkill is needed
    $ADB kill-server && timeout --signal=SIGKILL 20s $ADB start-server
fi


# Get ip from parameters or from adb shell
if [[ -z $1 ]]; then
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
else
    IP=$1
fi

#Validated IP
VALID_IP=$(echo $IP | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")
if [[ -z $VALID_IP ]]; then
    echo "air-adb: $IP invalid ip address"
    exit 1
fi

# use port argument if exists
if [[ -n $2 ]]; then
    PORT=$2
fi

# Adb stuff
set -e
$ADB tcpip $PORT 
$ADB connect $VALID_IP:$PORT
if [[ $? -eq 0 ]]; then
    MODEL=$($ADB devices -l | grep $VALID_IP | awk '{print $4}' | awk -F ':' '{print $2}') 
    echo "adb-air: $MODEL connected with ip: $VALID_IP, port: $PORT"
    exit 0
else
    echo "adb-air: Device  not connected"
    exit 1
fi
