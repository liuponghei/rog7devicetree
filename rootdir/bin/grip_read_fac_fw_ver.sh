#!/vendor/bin/sh
FAC_FW_VER=`cat /vendor/factory/fw_version.txt | grep "FW Version" | cut -d "." -f 3`
setprop vendor.grip.selected_fw $FAC_FW_VER
