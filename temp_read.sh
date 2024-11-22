#!/bin/bash
SCRIPT_PATH=$(dirname "$0")

DEVICE=$1
PROPERTY=$2

if [ -z "${PROPERTY}" ]; then
   PROPERTY=$(echo $DEVICE | awk -F ',' '{printf("%s", $2)}')
   DEVICE=$(echo $DEVICE | awk -F ',' '{printf("%s", $1)}')
else
   PROPERTY="temperature"
fi

cat $SCRIPT_PATH/temperature.txt | grep "/dev/$DEVICE/$PROPERTY" | awk 'BEGIN { FS = ":" }; {printf $2}'
