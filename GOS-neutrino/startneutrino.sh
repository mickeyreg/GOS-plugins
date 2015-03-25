#!/bin/sh

# Graterlia OS
# homepage: http://graterlia.xunil.pl
# e-mail: nbox@xunil.pl
#
# skrypt uruchomieniowy dla roznego rodzaju Neutrino
# wersja 2015-03-23

. /etc/sysconfig/gfunctions #wczytanie funkcji wsp�lnych dla skrypt�w Graterlia
# zaladowanie informacji o konfiguracji o ile istnieje
if [ -e /etc/sysctl.gos ]; then
	. /etc/sysctl.gos
fi
if [ -e /usr/ntrino/version ]; then
	. /usr/ntrino/version
else
	imagename='Neutrino'
fi

export LD_LIBRARY_PATH=/usr/ntrino/lib/:$LD_LIBRARY_PATH #tu trzymamy biblioteki specyficzne dla neutrino

[ -e /dev/input/nevis_ir ] || ln -sf /dev/input/event0 /dev/input/nevis_ir #obsluga pilota dla spark7162 ma byc event1
#[ -e /usr/local/bin ] || ln -sf /usr/ntrino/bin /usr/local/bin #w razie czego
[ -e /.version ] || ln -sf /usr/ntrino/version /.version #info o wersji wyswietlane w neutrino
#[ -e /etc/cron/hourly/GetWeather ] || ln -sf /etc/ntrino/plugins/Weather/GetWeather /etc/cron/hourly/GetWeather #pogoda na infobarze
/etc/init.d/gbootlogo stop

doStartupActions(){
	[ -z "$oPLIdbgFolder" ] && oPLIdbgFolder='/hdd'
	echo $oPLIdbgFolder
	#czy logowac?
	if [ "$oPLIdbg" == "on" ]; then
		DebugPlace=' -v 3 >>$oPLIdbgFolder/neutrino.log 2>&1'
	else
		DebugPlace=' -v 0 >>/dev/null 2>&1'
	fi
	
	echo 1 > /proc/sys/vm/drop_caches #czyscimy cache
	stfbcontrol a 255
	echo "starting $imagename->"
	echo "$imagename">/dev/vfd
	echo "0" > /proc/progress
} 

until false
do
	doStartupActions
	eval "/usr/ntrino/bin/neutrino ${DebugPlace}"
	rtv=$?
    echo "Neutrino ended <- RTV: " $rtv
    #nie wiem, czy to prawda, ale BP twierdzi, ze przeladowanie bpamod poprawia pare rzeczy
    rmmod bpamem
    insmod /lib/modules/bpamem.ko
    case "$rtv" in
		0) echo "$rtv - shutdown"
		   case "$TUNER" in
			   spark)echo "off">/dev/vfd;;
			   *)echo "SHUTDOWN">/dev/vfd;;
		   esac
		   sync
		   init 0
		   exit 0
		   ;;
		1|2) echo "$rtv - REBOOT"
		   echo " RE-boot">/dev/vfd
		   sync
		   init 6
		   exit 0
		   ;;
		3) echo "3"
		   ;; 
		*) echo "* - ERROR $rtv"
		   case "$TUNER" in
			   spark)echo "E $rtv">/dev/vfd;;
			   *)echo "ERR $rtv">/dev/vfd;;
		   esac
		   sleep 1
		   ;;
      esac
done  