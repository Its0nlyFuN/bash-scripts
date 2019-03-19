#!/bin/bash
# by torvic9
# Contributors and testers:
# Richard Gladman, William Pursell, SGS, mbb, mbod, Manjaro Forum, StackOverflow

runffm() {
	if [[ -d $WORKDIR/ffmpeg-4.1 ]] ; then rm -rf $WORKDIR/ffmpeg-4.1 ; fi
	tar xf $WORKDIR/ffmpeg.tar.bz2 -C $WORKDIR
	cd $WORKDIR/ffmpeg-4.1
	local RESFILE="$WORKDIR/runffm"
	./configure --quiet --disable-debug --enable-static --enable-gpl --disable-nvdec --disable-nvenc \
	--disable-ffnvcodec --disable-vaapi --disable-vdpau --disable-doc --disable-appkit \
	--disable-avfoundation --disable-sndio --disable-schannel --disable-securetransport \
	--disable-amf --disable-cuvid  --disable-d3d11va --disable-dxva2
	/usr/bin/time -f %e -o $RESFILE make -s -j$(nproc) &>/dev/null &
	local PID=$!
	echo -n -e "* FFmpeg compilation:\t\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep .2; done
	printf "\b " ; cat $RESFILE
	echo "FFmpeg compilation: $(cat $RESFILE)" >> $LOGFILE
	cd ../..
	rm -rf $WORKDIR/ffmpeg-4.1/
	return 0
}

runxz() {
	gunzip -k -f -q $WORKDIR/kernel41.tar.gz
	local RESFILE="$WORKDIR/runxz"
 	/usr/bin/time -f %e -o $RESFILE xz -z -T$(nproc) --lzma2=preset=6e,pb=0 -Qqq -f $WORKDIR/kernel41.tar &
	local PID=$!
	echo -n -e "* XZ compression:\t\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep .2; done
	printf "\b " ; cat $RESFILE
	echo "XZ compression: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runblend() {
	unzip -qqj $WORKDIR/blender.zip -d $WORKDIR/blender
	local RESFILE="$WORKDIR/runblend"
	local TMP="$WORKDIR"
	local BLENDER_USER_CONFIG="$WORKDIR"
	/usr/bin/time -f %e -o $RESFILE blender -b $WORKDIR/blender/scene-Helicopter-27.blend -o $WORKDIR/blenderheli.png -f 1 --verbose 0 &>/dev/null &
	local PID=$!
	echo -n -e "* Blender render:\t\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep .2; done
	printf "\b " ; cat $RESFILE
	echo "Blender render: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runperf() {
	local RESFILE="$WORKDIR/runperf"	
	perf bench -f simple sched messaging -p -t -g 25 -l 10000 1> $RESFILE &
	local PID=$!
	echo -n -e "* Perf sched:\t\t\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep .5; done
	printf "\b " ; cat $RESFILE
	echo "Perf sched: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runperf2() {
	local RESFILE="$WORKDIR/runperf2"	
	/usr/bin/time -f%e -o $RESFILE perf bench numa mem -t $(nproc) -T 512 -p 1 -s 0 \
	-l 200 -zZq &>/dev/null &
	local PID=$!
	echo -n -e "* Perf NUMA Mem:\t\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep .2; done
	printf "\b " ; cat $RESFILE
	echo "Perf NUMA Mem: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runpi() {
	local RESFILE="$WORKDIR/runpi" 
	/usr/bin/time -f%e -o $RESFILE bc -l -q <<< "scale=6666; 4*a(1)" 1>/dev/null &
	local PID=$!
	echo -n -e "* Calculating 6666 digits of pi:\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep .2; done
	printf "\b " ; cat $RESFILE
	echo "Calculating 6666 digits of pi: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

rundarkt() {
	local RESFILE="$WORKDIR/rundarkt" 	
	darktable-cli $WORKDIR/bench.srw $WORKDIR/benchie_$CDATE.jpg --core --tmpdir $WORKDIR \
	--configdir $WORKDIR --disable-opencl -d perf 2>/dev/null | awk '/dev_process_export/{print $1}' > $RESFILE &
	local PID=$!
	echo -n -e "* Darktable RAW conversion:\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep .2; done
	sed -i 's/.\{3\}$//;s/,/./' $RESFILE
	printf "\b " ; cat $RESFILE
	echo "Darktable RAW conversion: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runsysb1() {
	local RESFILE="$WORKDIR/runsysb1"
 	/usr/bin/time -f %e -o $RESFILE sysbench --threads=$(nproc) --verbosity=0 --events=20000 \
 	--time=0 cpu run --cpu-max-prime=60000 &
	local PID=$!	
	echo -n -e "* Sysbench CPU:\t\t\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep .2; done
	printf "\b " ; cat $RESFILE
	echo "Sysbench CPU: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runsysb2() {
	local RESFILE="$WORKDIR/runsysb2"
 	/usr/bin/time -f %e -o $RESFILE sysbench --threads=$(nproc) --verbosity=0 --time=0 \
 	memory run --memory-total-size=80G --memory-block-size=4K --memory-oper=write --memory-access-mode=rnd &>/dev/null &
	local PID=$!	
	echo -n -e "* Sysbench RAM write:\t\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep .2; done
	printf "\b " ; cat $RESFILE
	echo "Sysbench RAM write: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runsysb3() {
	local RESFILE="$WORKDIR/runsysb2"
 	/usr/bin/time -f %e -o $RESFILE sysbench --threads=$(nproc) --verbosity=0 --time=0 \
 	memory run --memory-total-size=80G --memory-block-size=4K --memory-oper=read \
 	--memory-access-mode=rnd &>/dev/null &
	local PID=$!	
	echo -n -e "* Sysbench RAM read:\t\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep .2; done
	printf "\b " ; cat $RESFILE
	echo "Sysbench RAM read: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

killproc() {
	echo -e "\n*** Received SIGINT, aborting! ***\n"
	kill -- -$$ && exit 2
}

exitproc() {
	echo -e "Removing temporary files...\n"
	for i in $WORKDIR/{run*,benchie_*.jpg,kernel41.tar.xz,blender*.png,darktablerc,data.db,blender} ; do
		if [ -f $i ] ; then rm $i ; fi
		if [ -d $i ] ; then rm -r $i ; fi
	done
	rm $(echo $LOCKFILE)
}

set -e
export LANG=C
WORKDIR="$1"
VER="v0.6"
CDATE=`date +%F-%H%M`
RAMSIZE=$(( `awk '/MemAvailable/{print $2}' /proc/meminfo` / 1024 ))
#NUMASIZE=$(( $RAMSIZE / 2 / $(nproc) ))
NRTESTS=10
SYSINFO=`inxi -c0 -v | sed "s/Up:.*//;s/inxi:.*//;s/Storage:.*//"`

if [[ -z $1 ]] ; then
	echo "Please specify the full path for the temporary directory! Aborting."
	exit 1
fi

[[ "${WORKDIR:0:1}" != "/" ]] && WORKDIR="$PWD/$WORKDIR"
if [[ ! -d "$WORKDIR" ]] ; then
	read -p "The specified directory $WORKDIR does not exist. Create it (y/N)? " DCHOICE
	if [[ $DCHOICE = "y" || $DCHOICE = "Y" ]] ; then
		mkdir -p $WORKDIR
	else
		exit 1
	fi
fi

LOGFILE="$WORKDIR/benchie_${CDATE}.log"
LOCKFILE=`mktemp $WORKDIR/benchie.XXXX`

read -p "It is recommended to drop the caches before starting, do you want \
to do that now? Careful, root privileges needed! (y/N)" DCHOICE
if [[ $DCHOICE = "y" || $DCHOICE = "Y" ]]; then
	su -c "echo 3 > /proc/sys/vm/drop_caches"
fi

echo -e "Checking and downloading missing test files...\n"
if [[ ! -f $WORKDIR/kernel41.tar.gz ]]; then
	wget --show-progress -qO $WORKDIR/kernel41.tar.gz https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.1.tar.gz
fi
if [[ ! -f $WORKDIR/bench.srw && ! -f $WORKDIR/bench.srw.xmp ]]; then
 	wget --show-progress -qO $WORKDIR/bench.srw http://www.mirada.ch/bench.SRW
 	wget --show-progress -qO $WORKDIR/bench.srw.xmp http://www.mirada.ch/bench.SRW.xmp
fi
if [[ ! -f $WORKDIR/ffmpeg.tar.bz2 ]]; then
	wget --show-progress -qO $WORKDIR/ffmpeg.tar.bz2 https://ffmpeg.org/releases/ffmpeg-4.1.tar.bz2
fi
if [[ ! -f $WORKDIR/blender.zip ]]; then
	wget --show-progress -qO $WORKDIR/blender.zip https://download.blender.org/demo/test/Demo_274.zip
fi

printf "\n"
echo "======__==__ ============================ _____======="
echo "=====|  \/  |===== MINI BENCHMARKER =====| ___ ))====="
echo "=====| |\/| |=====      torvic9     =====| ___ \======"
echo "=====|_|==|_|=====       $VER       =====|_____//====="
echo "======================================================"

# start
trap killproc INT
trap exitproc EXIT
runperf ; sleep 2
runperf2 ; sleep 2
runpi ; sleep 2
runsysb1 ; sleep 2
runsysb2 ; sleep 2
runsysb3 ; sleep 2
runxz ; sleep 2
runffm ; sleep 2
rundarkt ; sleep 2
runblend ; sleep 2

unset arrayz; unset ARRAY
# arrayn not used currently
# arrayn=(`awk -F': ' '{print $1}' $LOGFILE`)
arrayz=(`awk -F': ' '{print $2}' $LOGFILE`)

for ((i=0 ; i<$(( $NRTESTS - 4)) ; i++)) ; do
	ARRAY[$i]="$(echo "scale=3; sqrt(${arrayz[$i]}*800)" | bc -l)"
done
for ((i=$(( $NRTESTS - 4 )) ; i<$NRTESTS ; i++)) ; do
	ARRAY[$i]="$(echo "scale=3; sqrt(${arrayz[$i]}*1000)" | bc -l)"
done

TTIME="$(echo "${arrayz[@]}" | sed 's/ /+/g' | bc)"
INTSCORE="$(IFS="+" ; bc <<< "scale=3; ${ARRAY[*]}")"
SCORE="$(bc <<< "scale=3; $INTSCORE / $NRTESTS")"
echo "------------------------------------------------------"
echo "Total time in seconds:"
echo "------------------------------------------------------"
echo $TTIME ; echo "Total time (s): $TTIME" >> $LOGFILE
echo "------------------------------------------------------"
echo "Total score (lower is better):"
echo "------------------------------------------------------"
echo $SCORE ; echo "Total score: $SCORE" >> $LOGFILE
echo $SYSINFO >> $LOGFILE
echo "======================================================"
exit 0
