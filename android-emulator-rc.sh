#!/bin/sh

export PATH=/sbin:/bin:/usr/sbin/:/usr/bin
DESC=android-emulator

log_daemon_msg() {
    echo "* $1"
}

RUNAS=androidemulator
ANDROID_SDK=/opt/Android/Sdk
TARGET_SDK=android-24
PIDFILE=/var/run/android_emulator.pid
LOGFILE=/var/log/android_emulator.log
SHOULD_UPDATE_SDK=0
SDCARD_SIZE=100M
PARTITIONSIZE=500

#Override the ANDROID_SDK and EMULATOR_USER in this script
test -f /etc/android_emulator.rc &&  . /etc/android_emulator.rc

export ANDROID_SDK
export PATH=/usr/local/opt/e2fsprogs/sbin:$ANDROID_SDK/tools/bin/:$ANDROID_SDK/emulator:$ANDROID_HOME/tools/bin/:$ANDROID_HOME/emulator:$PATH


start_emulator() {
    if [ -f $PIDFILE ] && kill -0 "$(cat $PIDFILE)"; then
	echo 'Service already running' >&2
	return 1
    fi

    if [ x$SHOULD_UPDATE_SDK = x1 ] ; then
	# note that this *will* slow down your boot process. If it fails (because we don't have permission to write to the SDK)
	# we will still continue to run
	su -c "$ANDROID_SDK/tools/bin/sdkmanager --install  emulator 'system-images;$TARGET_SDK;google_apis;x86_64'" "$RUNAS" > $LOGFILE 2>&1 || exit 0
    fi

    su -c "$ANDROID_SDK/tools/bin/avdmanager create avd -d 'Nexus 5X' -f -n 'default_emulator' -b 'x86_64' -k 'system-images;$TARGET_SDK;google_apis;x86_64' -c $SDCARD_SIZE" "$RUNAS" > $LOGFILE 2>&1 || exit 1
    HOMEDIR="$(echo $(getent passwd $RUNAS )| cut -d : -f 6)"
    cd $HOMEDIR/.android/avd/default_emulator.avd
    height=`cat config.ini | grep hw.lcd.height |  cut -d '=' -f 2`
    width=`cat config.ini | grep hw.lcd.width |  cut -d '=' -f 2`

    touch "$LOGFILE"
    chown "$RUNAS" "$LOGFILE"
    CMD="$ANDROID_SDK/emulator/emulator @default_emulator -skin ${width}x${height} -partition-size $PARTITIONSIZE -no-window &> $LOGFILE  & echo \$!"
    su -c "$CMD" "$RUNAS" > "$PIDFILE"
    log_daemon_msg "Started android emulator"
}

stop_emulator() {
    if [ ! -f "$PIDFILE" ] || ! kill -0 "$(cat "$PIDFILE")"; then
	echo 'Service not running' >&2
	return 1
    fi
    log_daemon_msg "Stopping android emulator"
    kill -15 $(cat $PIDFILE) && rm -f $PIDFILE
    log_daemon_msg "Stopped android emulator".
}

case "$1" in
  start)
	log_daemon_msg "Starting $TARGET_SDK emulator"
	start_emulator
  ;;
  stop)
	stop_emulator
  ;;
  restart|force-reload)
    $0 stop
    sleep 5
    $0 start
  ;;
esac

exit 0
