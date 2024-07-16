#!/vendor/bin/sh

val=0

if [ -e /mnt/vendor/persist/asus_ufs_check.bin ] ; then
	val=`cat /mnt/vendor/persist/asus_ufs_check.bin`
else
	echo "[ufs]asus_ufs_check.bin is not exist" > /dev/kmsg
fi

echo "[ufs]asus_ufs_init ($val)" > /dev/kmsg


ufs_ctrl=`getprop persist.vendor.asus.ufs.ctrl`

if [ "$ufs_ctrl" = "1" ] ; then
	#do nothing
	echo -n
else
	echo 0 > /sys/devices/platform/soc/1d84000.ufshc/qcom/asus_ufs_lock
fi

echo $val > sys/module/ufs_qcom/parameters/asus_ufs_uic_check
setprop vendor.asus.sys.asus_ufs_check $val
