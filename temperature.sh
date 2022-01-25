#!/bin/bash
SCRIPT_PATH=$(dirname "$0")


## Read HDD temperature with smartctl
disks=$(lsblk -o NAME,TYPE | grep -E 'disk'| awk '{printf " "$1}')

tempString="update:$(date +%F_%H:%M:%S)\n"
declare -a discoveryArray;

for dev in $disks;
    do
      device="/dev/"${dev::5};

      modelName=$(sudo smartctl -i $device | grep -E "Device Model:|Model Number:" | awk -F ':' '{printf("%s", $2)}' | sed 's/ //g')
      temperature=$(sudo smartctl -A $device | grep -E "Temperature:|Temperature_Celsius")

      if [ ${temperature::3} == "194" ]; then
         temp=$(awk '{printf int($10)}' <(echo $temperature))
         #echo $device "Temperature: $temp C";
	 ## tempString="$tempString$device/name:$modelName\n"
         tempString="$tempString$device/temperature:$temp\n"
	discoveryArray+=("{\"{#DEVICE_NAME}\":\"${dev::5}\",\"{#DEVICE_MODEL}\":\"$modelName\",\"{#DEVICE_TYPE}\":\"storage\"}")
      else
         temp=$(awk '{printf int($2)}' <(echo $temperature))
         #echo $device "Temperature: $temp C";
	 ## tempString="$tempString$device/name:$modelName\n"
         tempString="$tempString$device/temperature:$temp\n"
	discoveryArray+=("{\"{#DEVICE_NAME}\":\"${dev::5}\",\"{#DEVICE_MODEL}\":\"$modelName\",\"{#DEVICE_TYPE}\":\"storage\"}")
      fi
      ## echo -e "\n"
done


## Read System temperature with sensors
Sensors=$(sensors);

parseSensor()
{
   local line=$1;
   local cpuNumber=$2;
   local sensorName=$(echo $line | awk -F ':' '{printf("%s", tolower($1))}' | sed 's/ //g');
   local tempValue=$(echo $line | awk -F ':' '{printf("%d ", $2)}');
   if [[ "$tempValue" -lt "0" ]]; then
      return;
   fi
   if [ ! -z "$cpuNumber" ]; then
       echo "/dev/cpu${cpuNumber}_${sensorName}/temperature:$tempValue\n";
   else
       echo "/dev/mb_${sensorName}/temperature:$tempValue\n";
   fi
}

cpuDiscovery()
{
   local line=$1;
   local cpuNumber=$2;

   local tempValue=$(echo $line | awk -F ':' '{printf("%d ", $2)}');
   if [[ "$tempValue" -lt "0" ]]; then
      return;
   fi
   local deviceName=$(echo $line | awk -F ':' '{printf("%s", tolower($1))}' | sed 's/ //g');
   local sensorName=$(echo $line | awk -F ':' '{printf("%s", $1)}' | sed 's/ /_/g');
   if [ ! -z "$cpuNumber" ]; then
       echo "{\"{#DEVICE_NAME}\":\"cpu${cpuNumber}_$deviceName\",\"{#DEVICE_MODEL}\":\"CPU${cpuNumber}-${sensorName}\",\"{#DEVICE_TYPE}\":\"cpu\"}";
   else
       echo "{\"{#DEVICE_NAME}\":\"mb_$deviceName\",\"{#DEVICE_MODEL}\":\"MB-$sensorName\",\"{#DEVICE_TYPE}\":\"mb\"}";
   fi
}


while IFS= read -r line; do
    if echo "$line" | grep -q 'Core 0:\|Package\|coretemp'; then
        if [[ $line == *"coretemp"* ]]; then
           cpuNumber=$(echo $line | awk -F '-' '{printf("%d ", $3)}');
        else
           tempString=$tempString$(parseSensor "$line" $cpuNumber);
           discoveryArray+=($(cpuDiscovery "$line" $cpuNumber))
        fi
    fi
    if echo "$line" | grep -q 'SYSTIN:\|AUXTIN.*:'; then
        tempString=$tempString$(parseSensor "$line");
        discoveryArray+=($(cpuDiscovery "$line"))
    fi
done < <(printf '%s\n' "$Sensors")


function join_by { local d=${1-} f=${2-}; if shift 2; then printf %s "$f" "${@/#/$d}"; fi; }

echo -e $tempString > $SCRIPT_PATH/temperature.txt
chmod 0666 $SCRIPT_PATH/temperature.txt


discoveryString="["$(join_by ',' ${discoveryArray[*]})"]"

echo -e $discoveryString > $SCRIPT_PATH/discovery.txt
chmod 0666 $SCRIPT_PATH/discovery.txt
