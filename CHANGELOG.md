
## [v1.3.0]

> [!WARNING]  
> **Breaking change!**

### Added
+ Added support several sensors from NVMe disks
* **WARNING!** This will lead to breaking existing autodiscovery device name from `nvme0` to `nvme0,temperature1`
* with loosing history monitored data


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
