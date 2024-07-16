
cc=`getprop ro.boot.country_code`
echo cc=$cc

if [ -e "/data/vendor/BBY/ufs_ctrl_list.cdn" ] ; then
	echo ufs cdn file exist
else
	echo ufs cdn file not exist
	exit
fi

exec < /data/vendor/BBY/ufs_ctrl_list.cdn
#line_num=`wc -l /data/vendor/BBY/ufs_ctrl_list.cdn`

while read line
do
	#echo $line
	if [ "$cc" == "$line" ] || [ "ALL" == "$line" ]; then
		echo $cc and $line is match
		setprop persist.vendor.asus.ufs.ctrl 1
		exit
	fi
done

echo Not found matched $cc
setprop persist.vendor.asus.ufs.ctrl 0
