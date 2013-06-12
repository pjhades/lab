#!/bin/bash


#export XMODIFIRES=@im=SCIM
#export GTK_IM_MODULE="scim-bridge"
#export QT_IM_MODULE="scim-bridge"
#scim-bridge -d

fcitx &

[ -f ~/.xprofile ] && . ~/.xprofile
/usr/bin/xscreensaver -no-splash &

exec openbox
#exec xfce4-session
