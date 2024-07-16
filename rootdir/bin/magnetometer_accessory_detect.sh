#!/vendor/bin/sh

#export PATH=/vendor/bin
GAMEPAD_PATH="/sys/bus/platform/devices/a600000.ssusb/Gamepad_enable"
#echo $GAMEPAD_PATH
GAMEPAD_DATA=`cat $GAMEPAD_PATH`
#echo $GAMEPAD_DATA

GAMEPAD_CONNECT_PROP="vendor.asus.GamePad_connect"
#echo $GAMEPAD_CONNECT_PROP
GAMEPAD_CONNECT_VAL=`getprop $GAMEPAD_CONNECT_PROP`
#echo $GAMEPAD_CONNECT_VAL

if [ 1 == $GAMEPAD_DATA ] && [ -z "$GAMEPAD_CONNECT_VAL" ]; then
	echo "Gamepad Connect by NULL"
	setprop vendor.asus.GamePad_connect 1
elif [ 1 == $GAMEPAD_DATA ] && [ -n "$GAMEPAD_CONNECT_VAL" ] && [ 0 == $GAMEPAD_CONNECT_VAL ]; then
	echo "Gamepad Connect"
	setprop vendor.asus.GamePad_connect 1
elif [ 0 == $GAMEPAD_DATA ] && [ -n "$GAMEPAD_CONNECT_VAL" ] && [ 1 == $GAMEPAD_CONNECT_VAL ]; then
	echo "Gamepad Unconnect"
	setprop vendor.asus.GamePad_connect 0
else
	echo "No change"
fi
