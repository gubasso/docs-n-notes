# It

Main and general notes

**wipe / erase / “format” disk or partition**

- pv --timer --rate --stop-at-size -s "$(blockdev --getsize64 /dev/sd"XY" )" /dev/zero > /dev/sd"XY"
- cp /dev/zero /dev/sd"XY"
- dd if=/dev/zero of=/dev/sdX bs=4096 status=progress
