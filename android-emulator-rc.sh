#!/bin/sh

export PATH=/sbin:/bin:/usr/sbin/:/usr/bin
DESC=android-emulator


. /lib/lsb/init-functions

RUNAS=android_emulator
ANDROID_SDK=/opt/Android/Sdk
TARGET_SDK=android-24
PIDFILE=/var/run/android_emulator.pid
LOGFILE=/var/log/android_emulator.log

#Override the ANDROID_SDK and EMULATOR_USER in this script
test -f /etc/android_emulator.rc &&  . /etc/android_emulator.rc

export PATH=/usr/local/opt/e2fsprogs/sbin:$ANDROID_SDK/tools/bin/:$ANDROID_SDK/emulator:$ANDROID_HOME/tools/bin/:$ANDROID_HOME/emulator:$PATH


start_emulator() {
    if [ -f $PIDFILE ] && kill -0 "$(cat $PIDFILE)"; then
	echo 'Service already running' >&2
	return 1
    fi

    # note that this *will* slow down your boot process
    su -c "$ANDROID_SDK/tools/bin/sdkmanager --install  emulator 'system-images;$TARGET_SDK;google_apis;x86_64'" "$RUNAS" || exit 1

    su -c "$ANDROID_SDK/tools/bin/avdmanager create avd -d 'Nexus 5X' -f -n 'default_emulator' -b 'x86_64' -k 'system-images;$TARGET_SDK;google_apis;x86_64' -c 100M" "$RUNAS" || exit 1
    HOMEDIR="$(echo $(getent passwd $RUNAS )| cut -d : -f 6)"
    cd $HOMEDIR/.android/avd/default_emulator.avd
    height=`cat config.ini | grep hw.lcd.height |  cut -d '=' -f 2`
    width=`cat config.ini | grep hw.lcd.width |  cut -d '=' -f 2`

    touch "$LOGFILE"
    chown "$RUNAS" "$LOGFILE"
    CMD="$ANDROID_SDK/emulator/emulator @default_emulator -skin ${width}x${height} -partition-size 500 -no-window &> $LOGFILE  & echo \$!"
    su -c "$CMD" "$RUNAS" > "$PIDFILE"
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
