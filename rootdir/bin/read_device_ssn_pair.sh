#!/vendor/bin/sh

ssn="$1"

deviceid=$(getprop vendor.asus.system.get.deviceid.num)
ssn=${ssn//\"}

query_ssn() {
  local ssn="$1"
  setprop vendor.asus.system.start.key.reinstall 1
  sleep 5
  setprop vendor.asus.system.start.key.reinstall 1
  echo "[rkp_reinstall]DeviceID reprovision done! "> /proc/asusevtlog
  setprop vendor.asus.check_trigger 1
  return 0
}

sleep 120
query_ssn "$ssn"
