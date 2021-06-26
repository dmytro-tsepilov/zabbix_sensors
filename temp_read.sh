#!/bin/bash
SCRIPT_PATH=$(dirname "$0")

DEVICE=$1
PROPERTY=$2

cat $SCRIPT_PATH/temperature.txt | grep "/dev/$DEVICE/$PROPERTY" | awk 'BEGIN { FS = ":" }; {printf $2}'
