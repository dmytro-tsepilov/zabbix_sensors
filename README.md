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
/dev/nvme0/temperature1:42
/dev/nvme0/temperature2:45
/dev/mb_systin/temperature:23
/dev/mb_auxtin0/temperature:19
/dev/mb_auxtin1/temperature:22
/dev/cpu0_packageid0/temperature:16
/dev/cpu0_core0/temperature:32
```

### Configure zabbix-agent

We need add custom fields to zabbix-agent configuration
1. Create empty file `/etc/zabbix/zabbix_agentd.d/userparams.conf` More info: [Zabbix Userparameters](https://www.zabbix.com/documentation/current/ru/manual/config/items/userparameters)
2. Add this lines to **userparams.conf**, and replace `#PATH_TO_SCRIPTS#` with real path to this files:  
```
UserParameter=System.temperature.discovery, cat #PATH_TO_SCRIPTS#/zabbix_sensors/discovery.txt
UserParameter=System.temperature[*], #PATH_TO_SCRIPTS#/zabbix_sensors/temperature.sh --read=$1
```
3. Check zabbix-agent daemon config `/etc/zabbix/zabbix_agentd.conf` for this line, add or uncomment if needed:
```
Include=/etc/zabbix/zabbix_agentd.d/*.conf
```
4. Restart zabbix-agent `service zabbix-agent restart`


### Setup monitoring on zabbix-server

* #### Manual setup sensors
1. TODO
* #### Setup using autodiscovery templates [Zabbix Low Level Discovery](https://www.zabbix.com/documentation/current/ru/manual/discovery/low_level_discovery)
1. Open zabbix configuration (Configuration -> Templates) and click Import button at right upper corner to impoort template
2. Choose file **zabbix_sensors_template.yaml** for import. It will create new group **Templates/Server hardware** and template **Template System Temperature**
3. Edit your Linux host monitored by zabbix agent and add template **Template System Temperature** to your host
4. Navigate to Host -> Discover rules, look for **Template System Temperature: System Temperature** rule in list
5. Check that rule have status **Enabled**
6. Run discovery for rule: Select rule's checkbox and click **Execute now** at the bottom of list.
