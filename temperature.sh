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
   line=$1;
   local sensorName=$(echo $line | awk -F ':' '{printf("%s", tolower($1))}' | sed 's/ //g');
   local temp=$(echo $line | awk -F ':' '{printf("%d ", $2)}');
   echo "/dev/$sensorName/temperature:$temp";
}

cpuDiscovery()
{
   line=$1;
   local deviceName=$(echo $line | awk -F ':' '{printf("%s", tolower($1))}' | sed 's/ //g');
   local sensorName=$(echo $line | awk -F ':' '{printf("%s", $1)}' | sed 's/ /_/g');
   echo "{\"{#DEVICE_NAME}\":\"$deviceName\",\"{#DEVICE_MODEL}\":\"$sensorName\",\"{#DEVICE_TYPE}\":\"cpu\"}";
}

while IFS= read -r line; do
    if echo "$line" | grep -q 'SYSTIN:'; then
	tempString=$tempString$(parseSensor "$line")"\n";
	discoveryArray+=($(cpuDiscovery "$line"))
    fi
    if echo "$line" | grep -q 'Core 0:'; then
	tempString=$tempString$(parseSensor "$line")"\n";
	discoveryArray+=($(cpuDiscovery "$line"))
    fi
    if echo "$line" | grep -q 'Package'; then
	tempString=$tempString$(parseSensor "$line")"\n";
	discoveryArray+=($(cpuDiscovery "$line"))
    fi
done < <(printf '%s\n' "$Sensors")


function join_by { local d=${1-} f=${2-}; if shift 2; then printf %s "$f" "${@/#/$d}"; fi; }

echo -e $tempString > $SCRIPT_PATH/temperature.txt
chown dimon:dimon $SCRIPT_PATH/temperature.txt


discoveryString="["$(join_by ',' ${discoveryArray[*]})"]"

echo -e $discoveryString > $SCRIPT_PATH/discovery.txt
chown dimon:dimon $SCRIPT_PATH/discovery.txt
