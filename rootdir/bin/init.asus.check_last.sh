#!/vendor/bin/sh

#echo $0 > /dev/kmsg
echo "ASDF: Check LastShutdown log." > /dev/kmsg

#Check if there is an abnormal shutdown occured
abnormal_restart_prop='vendor.asus.abnormal_restart'
dd if=/dev/block/bootdevice/by-name/ftm of=/data/vendor/logcat_log/miniramdump_header.txt bs=4 count=2
var=$(cat /data/vendor/logcat_log/miniramdump_header.txt)
if test "$var" = "Raw_Dmp!"
then
	setprop $abnormal_restart_prop "warm"
	fext="$(date +%Y%m%d-%H%M%S).txt"
	dd if=/dev/block/bootdevice/by-name/ftm of=/asdf/LastShutdownCrash_$fext skip=5500184 ibs=1 count=262144
	cat /asdf/LastShutdownCrash_$fext | grep -C 500 "Kernel panic" > /asdf/last_kmsg
	chmod 666 /asdf/last_kmsg
	chown system:system /asdf/last_kmsg

	kernel_panic_flag=`grep -c "Kernel panic" /asdf/last_kmsg`
	if [ "${kernel_panic_flag}" != "0" ]; then
		setprop $abnormal_restart_prop "kernel_panic"
	fi

	echo "ASDF: Found Mini Dump!" > /proc/asusevtlog
	echo "MiniDump" > /data/vendor/logcat_log/miniramdump_header.txt
	dd if=/data/vendor/logcat_log/miniramdump_header.txt of=/dev/block/bootdevice/by-name/ftm bs=4 count=2
	rm /data/vendor/logcat_log/miniramdump_header.txt
else
	# Remove old logs
	if [ -e /asdf/last_kmsg ]; then
		rm /asdf/last_kmsg
	fi
fi

rawdump_enable=`getprop ro.boot.rawdump_en`
if [ "${rawdump_enable}" = "1" ]; then
	dd if=/dev/block/bootdevice/by-name/rawdump of=/data/vendor/logcat_log/ramdump_header.txt bs=4 count=2
	var=$(cat /data/vendor/logcat_log/ramdump_header.txt)
	if test "$var" = "Raw_Dmp!"
	then
		echo "ASDF: Found Full Dump!" > /dev/kmsg
	fi
fi

reason=$(cat /proc/asusdebug-ponpoff)
reason_fault=$(cat /proc/asusdebug-ponpoff | grep -i FAULT_N)
#echo "reason is ${reason}"
#echo "reason_fault is ${reason_fault}"

if test -e "/asdf/pmic_fault_count.txt"; then
	var=$( cat /asdf/pmic_fault_count.txt )
	if [[ -n ${reason_fault} ]];then
	    var=$(($var+1))
	    echo ${var}>/asdf/pmic_fault_count.txt
	fi
	setprop vendor.asus.pmicfaultcount ${var}
else
	echo 0 >/asdf/pmic_fault_count.txt
	setprop vendor.asus.pmicfaultcount 0
fi

RECORD_MAX=1000
RECORD_TIME=`date "+%Y/%m/%d %H:%M:%S"`
if [[ -n ${reason} ]];then
    if test -e "/asdf/pmic_pon.txt"; then
        #get current lines save in /asdf/pmic_pon.txt
        CUR_LINES=$(wc -l /asdf/pmic_pon.txt | awk '{print $1}')
        if [ ${CUR_LINES} -gt ${RECORD_MAX} ];then
            #if over MAX record lines, delete first line
            sed -i '1d' /asdf/pmic_pon.txt
        fi
    fi
    #echo "write ${reason} to /asdf/pmic_pon.txt"
    echo "${reason} @${RECORD_TIME}" >> /asdf/pmic_pon.txt
fi

if test -e /asdf/last_kmsg; then
    #For checking panic in last_kmsg
    panicvar=$(cat /asdf/last_kmsg)
    #If not panic issue
    if [[ -z ${panicvar} ]];then
        #Parse "md_TZ_IMEM.BIN" "md_XBL_LOG.BIN" from ftm to asdf folder
        tmp=$(/vendor/bin/minidparse "md_TZ_IMEM.BIN" "md_XBL_LOG.BIN")
        echo "TZ/XBL Log info:$tmp" > /proc/asusevtlog
        #For NOC check
        if test -e /asdf/md_TZ_IMEM.BIN; then
            nocvar=$(cat /asdf/md_TZ_IMEM.BIN | grep -iE '\[.*\]\(.*NOC|\[.*\].*SPMI bus busy')
            if [[ -n ${nocvar} ]];then
                #Save NOC log to last_kmsg
                cat /asdf/md_TZ_IMEM.BIN | grep -iE '\[.*\]\(|\[.*\].*SPMI bus busy' > /asdf/last_kmsg
                #known issue pre-parse
                known_issue=0
                #1. mdsp noc issue
                nocvar=$(cat /asdf/last_kmsg | grep -iE '\[.*\]\(.*GEM_NOC 4 1 450e19')
                if [[ -n ${nocvar} ]];then
                    echo "##asusparse##:modem:noc" >> /asdf/last_kmsg
                    known_issue=1
                fi
                #2. pmic settling error/AOP
                nocvar=$(cat /asdf/last_kmsg | grep -ciE '\[.*\].*SPMI bus busy')
                if [ ${nocvar} -gt 5 ]; then
                    echo "##asusparse##:pmic:noc" >> /asdf/last_kmsg
                    known_issue=1
                fi
                #N. unknown noc issue
                if [ $known_issue -eq 0 ]; then
                    echo "##asusparse##:unknown:noc" >> /asdf/last_kmsg
                fi
            fi
            rm /asdf/md_TZ_IMEM.BIN
        fi
        #For XBL/UEFI log check
        if test -e /asdf/md_XBL_LOG.BIN; then
            #Save XBL log to last_kmsg
            cat /asdf/md_XBL_LOG.BIN | grep -E '^D\ -\ |^B\ -\ |\[ABL\]|^S\ -\ ' >> /asdf/last_kmsg
            #known issue pre-parse
            #1. mdsp noc issue
            nocvar=$(cat /asdf/last_kmsg | grep -iE 'OCP Occured')
            if [[ -n ${nocvar} ]];then
                echo "##asusparse##:pmic:ocp" >> /asdf/last_kmsg
            fi
            rm /asdf/md_XBL_LOG.BIN
        fi
    fi
fi

#echo "$0 EXIT" > /dev/kmsg
