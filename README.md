# Multitool

This script partitions, formats and installs grub on a removable device. The result is a USB stick that can boot multiple Linux distributions from `.iso` files. The stick can be used for emergency repairs, to experiment with different distributions, and to turn your friends to Linux. A weapon worthy of a true samurai.

### Usage
Typical usage of the script is shown below:
```
# ./multitool.sh /dev/sdc MULTITOOL
```

### Supported distributions
 - :heavy_check_mark: Tiny Core
 - :heavy_check_mark: Debian
 - :heavy_check_mark: OpenSUSE
 - :heavy_check_mark: Arch
 - :heavy_check_mark: Gentoo
 - :heavy_multiplication_x: FreeDOS (in progress)
 - :heavy_multiplication_x: Fedora
 - :heavy_multiplication_x: CentOS

### Warning
The script does include configuration to boot mentioned distributions, but does not include `.iso` files. These are to be downloaded separately and placed in `grub/multitool` directory. Some adjustments to the code may be needed in order to make newer versions work.