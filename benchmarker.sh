#!/bin/bash
# by torvic9
# Contributors and testers:
# Richard Gladman, William Pursell, SGS, mbb, mbod, Manjaro Forum

export LANG=C
VER="v0.4"
CDATE=`date +%F-%H%M`
TMPDIR="$1"
LOGFILE="$TMPDIR/benchie_${CDATE}.log"
#LOCKFILE="$TMPDIR/benchie.lock"
RAMSIZE=`awk '/MemAvailable/{print $2}' /proc/meminfo`
DEPS="$(pacman -Qkq {perf,unzip,darktable,sysbench,nasm,time,make} 2>/dev/null; echo $?)"
NRTESTS=7

if [[ -z $1 ]] ; then
	echo "Please specify the full path for the temporary directory! Aborting."
	exit 1
fi

if [[ ! -d $1 ]] ; then
	read -p "The specified directory does not exist. Create it (y/n)? " DCHOICE
	if [[ $DCHOICE = "y" ]] ; then
		mkdir $TMPDIR
	else
		exit 1
	fi
fi

if [[ $DEPS != 0 ]] ; then
	echo "Some needed applications are not installed!"
	read -p "Install required packages (y/n)? " UCHOICE
	if [[ $UCHOICE = "y" ]] ; then
		sudo pacman -S nasm perf darktable sysbench time unzip make
	else
		exit 1
	fi
fi

read -p "It is recommended to drop the caches before starting, do you want \
to do that now? Careful, root privileges needed! (y/n)" DCHOICE
if [[ $DCHOICE = "y" ]]; then
	su -c "echo 3 > /proc/sys/vm/drop_caches"
fi

echo -e "Checking and downloading missing test files...\n"
if [[ ! -f $TMPDIR/silesia.zip ]]; then
 	wget -qO $TMPDIR/silesia.zip http://sun.aei.polsl.pl/~sdeor/corpus/silesia.zip
fi
if [[ ! -f $TMPDIR/bench.srw && ! -f $TMPDIR/bench.srw.xmp ]]; then
 	wget -qO $TMPDIR/bench.srw http://www.mirada.ch/bench.SRW
 	wget -qO $TMPDIR/bench.srw.xmp http://www.mirada.ch/bench.SRW.xmp
fi
if [[ ! -f $TMPDIR/ffmpeg.tar.bz2 ]]; then
	wget -qO $TMPDIR/ffmpeg.tar.bz2 https://ffmpeg.org/releases/ffmpeg-4.1.tar.bz2
fi

echo "========== MINI BENCHMARKER =========="
echo "==========      torvic9     =========="
echo "==========       $VER       =========="
echo "--------------------------------------"

runffm() {
	tar xf $TMPDIR/ffmpeg.tar.bz2 -C $TMPDIR
	cd $TMPDIR/ffmpeg-4.1
	local RESFILE="$TMPDIR/runffm"
	./configure --quiet --disable-debug --enable-static --enable-gpl --disable-nvdec --disable-nvenc \
	--disable-ffnvcodec --disable-vaapi --disable-vdpau --disable-doc --disable-appkit \
	--disable-avfoundation --disable-sndio --disable-schannel --disable-securetransport \
	--disable-amf --disable-cuvid  --disable-d3d11va --disable-dxva2
	/usr/bin/time -f %e -o $RESFILE make -s -j$(nproc) &>/dev/null &
	local PID=$!
	echo -n -e "FFmpeg compilation:\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep .2; done
	printf "\b " ; cat $RESFILE
	echo "FFmpeg compilation: $(cat $RESFILE)" >> $LOGFILE
	cd ../..
	rm -rf $TMPDIR/ffmpeg-4.1/
	return 0
}

runxz() {
 	unzip $TMPDIR/silesia.zip -d $TMPDIR/silesia/ &>/dev/null
 	tar cf $TMPDIR/silesia.tar $TMPDIR/silesia/ &>/dev/null
 	rm -rf $TMPDIR/silesia/
	local RESFILE="$TMPDIR/runxz"
 	/usr/bin/time -f %e -o $RESFILE xz -z -T$(nproc) -7 -Qq $TMPDIR/silesia.tar &
	local PID=$!
	echo -n -e "XZ compression:\t\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep .2; done
	printf "\b " ; cat $RESFILE
	echo "XZ compression: $(cat $RESFILE)" >> $LOGFILE
	rm $TMPDIR/*.xz
	return 0
}

runperf() {
	local RESFILE="$TMPDIR/runperf"	
	perf bench -f simple sched messaging -p -t -g 25 -l 10000 1> $RESFILE &
	local PID=$!
	echo -n -e "Perf sched:\t\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep .2; done
	printf "\b " ; cat $RESFILE
	echo "Perf sched: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runpi() {
	local RESFILE="$TMPDIR/runpi" 
	/usr/bin/time -f%e -o $RESFILE bc -l -q <<< "scale=6666; 4*a(1)" 1>/dev/null &
	local PID=$!
	echo -n -e "Calculating 6666 digits of pi:\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep .2; done
	printf "\b " ; cat $RESFILE
	echo "Calculating 6666 digits of pi: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

rundarkt() {
	local RESFILE="$TMPDIR/rundarkt" 	
	darktable-cli $TMPDIR/bench.srw $TMPDIR/benchie_$CDATE.jpg --core --tmpdir $TMPDIR \
	--configdir /dev/null --disable-opencl -d perf 2>/dev/null | awk '/dev_process_export/{print $1}' > $RESFILE &
	local PID=$!
	echo -n -e "Darktable RAW conversion:\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep .2; done
	sed -i 's/.\{3\}$//;s/,/./' $RESFILE
	printf "\b " ; cat $RESFILE
	echo "Darktable RAW conversion: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runsysb1() {
	local RESFILE="$TMPDIR/runsysb1"
 	/usr/bin/time -f %e -o $RESFILE sysbench --threads=$(nproc) --verbosity=0 --events=20000 \
 	--time=0 cpu run --cpu-max-prime=50000 &
	local PID=$!	
	echo -n -e "Sysbench CPU:\t\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep .2; done
	printf "\b " ; cat $RESFILE
	echo "Sysbench CPU: $(cat $RESFILE)" >> $LOGFILE
	return 0
}
runsysb2() {
	local RESFILE="$TMPDIR/runsysb2"
 	/usr/bin/time -f %e -o $RESFILE sysbench --threads=$(nproc) --verbosity=0 --time=0 memory \
 	run --memory-total-size=64G --memory-block-size=4K --memory-access-mode=rnd &>/dev/null &
	local PID=$!	
	echo -n -e "Sysbench RAM:\t\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep .2; done
	printf "\b " ; cat $RESFILE
	echo "Sysbench RAM: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

# start
runperf ; sleep 2
runpi ; sleep 2
runsysb1 ; sleep 2
runsysb2 ; sleep 2
runxz ; sleep 2
runffm ; sleep 2

#if [ $RAMSIZE -gt 2500000 ] ; then
rundarkt ; sleep 2
#else
#	echo -e "Darktable needs at least 2.5 GB of available RAM, aborting.\nTry running in runlevel 3."
#	exit 1
#fi

unset arrayz; unset ARRAY
# arrayn not used currently
# arrayn=(`awk -F': ' '{print $1}' $LOGFILE`)
arrayz=(`awk -F': ' '{print $2}' $LOGFILE`)

for ((i=0 ; i<$NRTESTS ; i++)) ; do
	ARRAY[$i]="$(echo "scale=3; sqrt(${arrayz[$i]}*20)" | bc -l)"
done
echo "--------------------------------------"
echo "Total time in seconds:"
echo "--------------------------------------"
echo "${arrayz[@]}" | sed 's/ /+/g' | bc
echo "--------------------------------------"
echo "Total score (higher is better):"
echo "--------------------------------------"
SCORE="$(IFS="+" ; bc <<< "scale=3; ${ARRAY[*]}")"
echo $SCORE ; echo "Total score: $SCORE" >> $LOGFILE
echo "======================================"
rm $TMPDIR/{runpi,runsysb1,runsysb2,runxz,rundarkt,runperf,runffm}
exit 0

