#!/bin/bash
SCRIPT_PATH=$(dirname "$0")

tempString="update:$(date +%F_%H:%M:%S)\n"
declare -a discoveryArray

## Read HDD temperature with smartctl
readDriveTemperature() {
   local disks=$(lsblk -o NAME,TYPE | grep -E 'disk$' | awk '{printf " "$1}')

   for dev in $disks; do
      local device="/dev/"${dev::5}

      local modelName=$(sudo smartctl -i $device | grep -E "Device Model:|Model Number:" | awk -F ':' '{printf("%s", $2)}' | xargs)
      local temperature=$(sudo smartctl -A $device | grep -E "Temperature:|Temperature_Celsius")
      local temperatureM=$(sudo smartctl -A $device | grep -E "Temperature Sensor")

      if [ ${temperature::3} == "194" ]; then
         local temp=$(awk '{printf int($10)}' <(echo $temperature))
         #echo $device "Temperature: $temp C";
         ## tempString="$tempString$device/name:$modelName\n"
         tempString="$tempString$device/temperature:$temp\n"
         discoveryArray+=("{\"{#DEVICE_NAME}\":\"${dev::5}\",\"{#DEVICE_MODEL}\":\"${modelName}\",\"{#DEVICE_TYPE}\":\"storage\"}")
      elif [ ! -z "${temperatureM}" ]; then
         while IFS= read -r tempSensor; do
            local temp=$(awk '{printf int($4)}' <(echo ${tempSensor}))
            local sensor=$(awk '{printf int($3)}' <(echo ${tempSensor}))
            tempString="$tempString$device/temperature${sensor}:${temp}\n"
            discoveryArray+=("{\"{#DEVICE_NAME}\":\"${dev::5},temperature${sensor}\",\"{#DEVICE_MODEL}\":\"${modelName}\",\"{#DEVICE_TYPE}\":\"storage\"}")
         done < <(printf '%s\n' "${temperatureM}")
      else
         local temp=$(awk '{printf int($2)}' <(echo $temperature))
         tempString="$tempString$device/temperature:$temp\n"
         discoveryArray+=("{\"{#DEVICE_NAME}\":\"${dev::5}\",\"{#DEVICE_MODEL}\":\"${modelName}\",\"{#DEVICE_TYPE}\":\"storage\"}")
      fi
      ## echo -e "\n"
   done
}

parseSensor() {
   local line=$1
   local deviceType=$2
   local cpuNumber=$3
   local deviceName=$4
   local sensorName=$(echo $line | awk -F ':' '{printf("%s", tolower($1))}' | sed 's/ //g')
   local tempValue=$(echo $line | awk -F ':' '{printf("%d ", $2)}')
   if [[ "$tempValue" -lt "0" ]]; then
      return
   fi

   case $deviceType in
   "cpu")
      echo "/dev/cpu${cpuNumber}_${sensorName}/temperature:$tempValue\n"
      ;;
   "mb")
      echo "/dev/mb_${sensorName}/temperature:$tempValue\n"
      ;;
   "wifi")
      echo "/dev/${deviceName}/temperature:$tempValue\n"
      ;;
   esac
}

cpuDiscovery() {
   local line=$1
   local deviceType=$2
   local cpuNumber=$3
   local deviceName=$4

   local tempValue=$(echo $line | awk -F ':' '{printf("%d ", $2)}')
   if [[ "$tempValue" -lt "0" ]]; then
      return
   fi

   if [ -z "${deviceName}" ]; then
      local deviceName=$(echo $line | awk -F ':' '{printf("%s", tolower($1))}' | sed 's/ //g')
   fi
   local sensorName=$(echo $line | awk -F ':' '{printf("%s", $1)}' | sed 's/ /_/g')

   case $deviceType in
   "cpu")
      echo "{\"{#DEVICE_NAME}\":\"cpu${cpuNumber}_$deviceName\",\"{#DEVICE_MODEL}\":\"CPU${cpuNumber}-${sensorName}\",\"{#DEVICE_TYPE}\":\"cpu\"}"
      ;;
   "mb")
      echo "{\"{#DEVICE_NAME}\":\"mb_$deviceName\",\"{#DEVICE_MODEL}\":\"MB-$sensorName\",\"{#DEVICE_TYPE}\":\"mb\"}"
      ;;
   "wifi")
      echo "{\"{#DEVICE_NAME}\":\"${deviceName}\",\"{#DEVICE_MODEL}\":\"${deviceName}\",\"{#DEVICE_TYPE}\":\"wifi\"}"
      ;;
   esac
}

## Read System temperature with sensors
readHardwareTemperature() {
   local Sensors=$(sensors)

   while IFS= read -r line; do
      ## Parse cpu sensors
      if echo "$line" | grep -q 'Core 0:\|Package\|coretemp'; then
         if [[ $line == *"coretemp"* ]]; then
            cpuNumber=$(echo $line | awk -F '-' '{printf("%d ", $3)}')
         else
            tempString=$tempString$(parseSensor "$line" "cpu" $cpuNumber)
            discoveryArray+=($(cpuDiscovery "$line" "cpu" $cpuNumber))
         fi
      fi

      ## Parse wifi sensors
      if echo "$line" | grep -q 'iwlwifi\|temp1:'; then
         if [[ $line == *"iwlwifi"* ]]; then
            wifiDevice=$line
         else
            if [ ! -z "${wifiDevice}" ]; then
               tempString=$tempString$(parseSensor "$line" "wifi" 0 "${wifiDevice}")
               discoveryArray+=($(cpuDiscovery "$line" "wifi" 0 "${wifiDevice}"))
               unset wifiDevice
            fi
         fi
      fi

      ## Parse motherboard sensors
      if echo "$line" | grep -q 'SYSTIN:\|AUXTIN.*:'; then
         tempString=$tempString$(parseSensor "$line" "mb")
         discoveryArray+=($(cpuDiscovery "$line" "mb"))
      fi
   done < <(printf '%s\n' "$Sensors")
}

readDriveTemperature
readHardwareTemperature

echo -e $tempString > $SCRIPT_PATH/temperature.txt
chmod 0666 $SCRIPT_PATH/temperature.txt


function arrayImplode {
   local array=("$@")
   local string

   for element in "${array[@]}"; do
      if [ -z "${string}" ]; then
         string="${element}"
      else
         string="${string},${element}"
      fi
   done

   echo "${string}"
}

discoveryString="["$(arrayImplode "${discoveryArray[@]}")"]"


echo -e $discoveryString > $SCRIPT_PATH/discovery.txt
chmod 0666 $SCRIPT_PATH/discovery.txt
