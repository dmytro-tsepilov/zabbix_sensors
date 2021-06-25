#!/bin/bash
DEVICE=$1
PROPERTY=$2

cat /home/dimon/zabbix/temperature.txt | grep "/dev/$DEVICE/$PROPERTY" | awk 'BEGIN { FS = ":" }; {printf $2}'
