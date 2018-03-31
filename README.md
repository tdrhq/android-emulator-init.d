Scripts to start/stop/restart an emulator, useful for init.d scripts (say for a Jenkins instance)

* Installation

`sudo make install`. It should, I think, properly set up your /etc/rcX.d scripts to start
an emulator under a dedicated user. It that user has access to your android sdk, which it also
assumes is in $HOME/Android/Sdk (where $HOME is *your* $HOME, not the script's).

Please send pull-requests if it doesn't work.
