
RCFILE?=/etc/android_emulator.rc
USER?=androidemulator
ANDROID_SDK?=~/Android/Sdk

install: copy-rc copy-conf add-user
uninstall: delete-files del-user

copy-rc:
	cp android-emulator-rc.sh  /etc/init.d/android-emulator
	ln -s /etc/init.d/android-emulator /etc/rc3.d/S99android-emulator

copy-conf:
	test -f ${RCFILE} || ${MAKE} copy-conf-force

copy-conf-force:
	echo "# if you update this file run: " > ${RCFILE}
	echo "$ sudo /etc/init.d/android-emulator install" >> ${RCFILE}
	echo "to ensure that all the SDK dependencies are installed" >> ${RCFILE}
	echo "ANDROID_SDK=${ANDROID_SDK}" >> ${RCFILE}
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
