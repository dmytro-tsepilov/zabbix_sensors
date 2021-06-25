# zabbix_sensors
Scripts for monitoring hardware temperature with zabbix on linux

## Installation

### Requirements
* [smartmontools](https://www.smartmontools.org/)  On ubntu: `apt-get install smartmontools` 
* lm-sensors  
On ubntu: `apt-get install lm-sensors`,  after instalation configure it with command `sensors-detect`
* [zabbix-agent](https://www.zabbix.com/ru/download_agents)

### Setup CRON job for getting sensors data

**smartmontools** require root access to be able read Storage sensors, so we add it to root CRON config.  
Run: `sudo crontab -e`  
Add line: `*/1 * * * * $HOME/zabbix_sensors/temperature.sh`

As a result script will generate two files:

* discovery.txt - JSON file with discovered sensors. More info: [Zabbix Low Level Discovery](https://www.zabbix.com/documentation/current/ru/manual/discovery/low_level_discovery).  
Example of **discovery.txt**:
```javascript
[{"{#DEVICE_NAME}":"sda","{#DEVICE_MODEL}":"TS128GMTS800S","{#DEVICE_TYPE}":"storage"},{"{#DEVICE_NAME}":"sdb","{#DEVICE_MODEL}":"ST8000VX004-2M1101","{#DEVICE_TYPE}":"storage"},{"{#DEVICE_NAME}":"systin","{#DEVICE_MODEL}":"SYSTIN","{#DEVICE_TYPE}":"cpu"},{"{#DEVICE_NAME}":"packageid0","{#DEVICE_MODEL}":"Package_id_0","{#DEVICE_TYPE}":"cpu"},{"{#DEVICE_NAME}":"core0","{#DEVICE_MODEL}":"Core_0","{#DEVICE_TYPE}":"cpu"}]
```

* temperature.txt - text file with temperature value for each of sensors in celsius.  
Example of **temperature.txt**:
```
update:2021-01-01_01:54:01
/dev/sda/temperature:50
/dev/sdb/temperature:46
/dev/systin/temperature:39
/dev/packageid0/temperature:32
/dev/core0/temperature:32
```

### Configure zabbix-agent

We need add custom fields to zabbix-agent configuration
1. Create empty file `/etc/zabbix/zabbix_agentd.d/userparams.conf` More info: [Zabbix Userparameters](https://www.zabbix.com/documentation/current/ru/manual/config/items/userparameters)
2. Add this lines to **userparams.conf**, and replace `#PATH_TO_SCRIPTS#` with real path to this files:  
```
UserParameter=System.temperature.discovery, cat #PATH_TO_SCRIPTS#/zabbix_sensors/discovery.txt
UserParameter=System.temperature[*], #PATH_TO_SCRIPTS#/zabbix_sensors/temp_read.sh $1 temperature
```
3. Check zabbix-agent daemon config `/etc/zabbix/zabbix_agentd.conf` for this line, add or uncomment if needed:
```
Include=/etc/zabbix/zabbix_agentd.d/*.conf
```
4. Restart zabbix-agent `service zabbix-agent restart`


### Setup monitoring on zabbix-server

1. TODO
2. TODO
