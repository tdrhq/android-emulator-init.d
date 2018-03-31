
RCFILE=/etc/android_emulator.rc
USER=androidemulator

install: copy-rc copy-conf add-user
uninstall: delete-files del-user

copy-rc:
	cp android-emulator-rc.sh  /etc/init.d/android-emulator
	ln -s /etc/init.d/android-emulator /etc/rc3.d/S99android-emulator

copy-conf:
	test -f ${RCFILE} || ${MAKE} copy-conf-force

copy-conf-force:
	echo "ANDROID_SDK=~/Android/Sdk" > ${RCFILE}
	echo "RUNAS=${USER}" >> ${RCFILE}
	cat default_configs >> ${RCFILE}

add-user:
	getent passwd ${USER} || adduser --disabled-password --gecos ",,," ${USER}
	adduser ${USER} kvm

delete-files:
	rm /etc/init.d/android-emulator || true
	rm /etc/rc3.d/S99android-emulator || true
	# we leave the config file around

del-user:
	deluser ${USER} || true
