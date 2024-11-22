
## [v1.4.0]

> [!WARNING]  
> **Breaking change!**

### Added
+ Added check for installed `lm_sensors`. If not installed, fetching according data will be skipped

### Changed
- Removed file `temp_read.sh` and replaced with reading script from main script `temperature.sh`.

### Migration
In `userparams.conf` file change `/some/path/temp_read.sh $1` to `/some/path/temperature.sh --read=$1`


## [v1.3.0]

> [!WARNING]  
> **Breaking change!**

### Added
+ Added support several sensors from NVMe disks
* **WARNING!** This will lead to breaking existing autodiscovery device name from `nvme0` to `nvme0,temperature1`
* **WARNING!** with loosing history monitored data
* The word `temperature` should be removed from parameters in user params for reading temp: `/some/path/temp_read.sh $1`

### Fixed
* Code formating

### Migration
In `userparams.conf` file change `/some/path/temp_read.sh $1 temperature` to `/some/path/temp_read.sh $1`


## [v1.2.0]

### Added
+ Added support wifi devices 'iwlwifi_1-virtual-0'
### Fixed
* Fixed support drive names with whitespaces in name (all whitespaces were trimmed before)
* Minor fixes and improvements


## [v1.1.0]

### Added
+ Added support multi-cpu instances
+ Added all AUXIN sensors
* Sensors with negative temperature will be ignored

### Fixed
*  Minor bugfixes


## [v1.0.0]
  
Initial version.

### Added
 
### Changed

### Fixed
