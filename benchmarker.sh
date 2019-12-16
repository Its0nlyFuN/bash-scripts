#!/bin/bash
# by torvic9
# Contributors and testers:
# Richard Gladman, William Pursell, SGS, mbb, mbod, Manjaro Forum, StackOverflow

runffm() {
	cd $WORKDIR
	tar xf ffmpeg.tar.gz
	cd ffmpeg-1529dfb
	local RESFILE="$WORKDIR/runffm"
	./configure --prefix=/tmp --disable-debug --enable-static --enable-stripping \
	  --disable-ladspa --disable-programs --disable-ffplay --disable-ffprobe \
	  --disable-doc --disable-network --disable-protocols --disable-lzma \
	  --disable-amf --disable-cuda-llvm --disable-cuvid --disable-d3d11va --disable-dxva2 \
	  --disable-nvdec --disable-nvenc --disable-vaapi --disable-vdpau --disable-sdl2 \
	  --disable-schannel --disable-securetransport --enable-libfontconfig \
	  --enable-libfreetype --enable-libspeex --enable-libvpx --enable-libopus --enable-libvorbis \
	  --enable-libx264 --enable-libx265 --enable-opengl --enable-libdrm --enable-gpl \
	  --enable-gmp --enable-gnutls --disable-avx512 --disable-fma4 --disable-autodetect \
	  --enable-version3 &>/dev/null
	/usr/bin/time -f %e -o $RESFILE make -s -j${CPUCORES} &>/dev/null &
	local PID=$!
	echo -n -e "\n* ffmpeg compilation:\t\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep .5; done
	printf "\b " ; cat $RESFILE
	echo "ffmpeg compilation: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runxz() {
	gunzip -k -f -q $WORKDIR/kernel44.tar.gz
	local RESFILE="$WORKDIR/runxz"
 	/usr/bin/time -f %e -o $RESFILE xz -z -T${CPUCORES} --lzma2=preset=6e,pb=0 -Qqq -f $WORKDIR/kernel44.tar &
	local PID=$!
	echo -n -e "* XZ compression:\t\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep .5; done
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
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep .5; done
	printf "\b " ; cat $RESFILE
	echo "Blender render: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runargon() {
	local RESFILE="$WORKDIR/runargon"
	/usr/bin/time -f %e -o $RESFILE argon2 BenchieSalt -i -t 60 -m 20 -p $CPUCORES &>/dev/null <<< $(dd if=/dev/urandom bs=1 count=64 status=none) &
	local PID=$!
	echo -n -e "* Argon2 hashing:\t\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep .5; done
	printf "\b " ; cat $RESFILE
	echo "Argon2 hashing: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runperf() {
	local RESFILE="$WORKDIR/runperf"
	perf bench -f simple sched messaging -p -g 20 -l 10000 1> $RESFILE &
	local PID=$!
	echo -n -e "* Perf sched:\t\t\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep 1; done
	printf "\b " ; cat $RESFILE
	echo "Perf sched: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runpi() {
	local RESFILE="$WORKDIR/runpi"
	gcc -O3 -march=native $WORKDIR/pi.c -o $WORKDIR/pi -lm -lgmp && sleep 1
	/usr/bin/time -f%e -o $RESFILE $WORKDIR/pi 60000000 1>/dev/null &
	local PID=$!
	echo -n -e "* Calculating 60m digits of pi:\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep .5; done
	printf "\b " ; cat $RESFILE
	echo "Calculating 66m digits of pi: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

rundarkt() {
	local RESFILE="$WORKDIR/rundarkt"
	darktable-cli $WORKDIR/bench.srw $WORKDIR/benchie_$CDATE.jpg --core --tmpdir $WORKDIR \
	--configdir $WORKDIR --disable-opencl -d perf 2>/dev/null | awk '/dev_process_export/{print $1}' > $RESFILE &
	local PID=$!
	echo -n -e "* Darktable RAW conversion:\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep .5; done
	sed -i 's/.\{3\}$//;s/,/./' $RESFILE
	printf "\b " ; cat $RESFILE
	echo "Darktable RAW conversion: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runsysb1() {
	local RESFILE="$WORKDIR/runsysb1"
 	/usr/bin/time -f %e -o $RESFILE sysbench --threads=$CPUCORES --verbosity=0 --events=10000 \
 	--time=0 cpu run --cpu-max-prime=80000 &
	local PID=$!
	echo -n -e "* Sysbench CPU:\t\t\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep .5; done
	printf "\b " ; cat $RESFILE
	echo "Sysbench CPU: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runsysb2() {
	local RESFILE="$WORKDIR/runsysb2"
 	/usr/bin/time -f %e -o $RESFILE sysbench --threads=$CPUCORES --verbosity=0 --time=0 \
 	memory run --memory-total-size=100G --memory-block-size=512K --memory-oper=write --memory-access-mode=rnd &>/dev/null &
	local PID=$!
	echo -n -e "* Sysbench RAM write:\t\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep .5; done
	printf "\b " ; cat $RESFILE
	echo "Sysbench RAM write: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runsysb3() {
	local RESFILE="$WORKDIR/runsysb2"
 	/usr/bin/time -f %e -o $RESFILE sysbench --threads=$CPUCORES --verbosity=0 --time=0 \
 	memory run --memory-total-size=100G --memory-block-size=4K --memory-oper=read \
 	--memory-access-mode=rnd &>/dev/null &
	local PID=$!
	echo -n -e "* Sysbench RAM read:\t\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep .5; done
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
	for i in $WORKDIR/{run*,benchie_*.jpg,kernel44.tar.xz,ffmpeg-1529dfb,blender*.png,darktablerc,data.db*,blender,pi} ; do
		if [ -f $i ] ; then rm $i ; fi
		if [ -d $i ] ; then rm -r $i ; fi
	done
	rm $(echo $LOCKFILE)
}

export LANG=C
WORKDIR="$1"
VER="v1.0"
CDATE=`date +%F-%H%M`
RAMSIZE=$(( `awk '/MemTotal/{print $2}' /proc/meminfo` / 1000000 ))
CPUCORES=`nproc`
#if [[ $CPUCORES -eq 1 ]] ; then
#	CPUCORES=2
#fi
CPUMHZ=$(lscpu -e=maxmhz | tail -n1)
CPUGHZ=$(echo "scale=1; ${CPUMHZ%%,*} / 1000" | bc)
COEFF=$(echo "scale=2; l(${CPUCORES} / 2 + ${CPUGHZ})" | bc -l)
NRTESTS=10
SYSINFO=$(inxi -c0 -v | sed "s/Up:.*//;s/inxi:.*//;s/Storage:.*//")

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
to do that now? Root priviledges needed! (y/N)" DCHOICE
if [[ $DCHOICE = "y" || $DCHOICE = "Y" ]]; then
	su -c "echo 3 > /proc/sys/vm/drop_caches"
	sync ; sleep 2
fi

echo -e "* Checking and downloading missing test files ...\n"
if [[ ! -f $WORKDIR/kernel44.tar.gz ]]; then
	wget --show-progress -qO $WORKDIR/kernel44.tar.gz https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.4.tar.gz
fi
if [[ ! -f $WORKDIR/bench.srw && ! -f $WORKDIR/bench.srw.xmp ]]; then
 	wget --show-progress -qO $WORKDIR/bench.srw http://www.mirada.ch/bench.SRW
 	wget --show-progress -qO $WORKDIR/bench.srw.xmp http://www.mirada.ch/bench.SRW.xmp
fi
if [[ ! -f $WORKDIR/ffmpeg.tar.gz ]]; then
	wget --show-progress -qO $WORKDIR/ffmpeg.tar.gz https://git.ffmpeg.org/gitweb/ffmpeg.git/snapshot/1529dfb73a5157dcb8762051ec4c8d8341762478.tar.gz
fi
if [[ ! -f $WORKDIR/blender.zip ]]; then
	wget --show-progress -qO $WORKDIR/blender.zip https://download.blender.org/demo/test/Demo_274.zip
fi
if [[ ! -f $WORKDIR/pi.c ]]; then
	wget --show-progress -qO $WORKDIR/pi.c https://gmplib.org/download/misc/gmp-chudnovsky.c
fi

echo -e "Starting ...\n"
echo "=====__==__ ========================== _____======"
echo "====|  \/  |==== MINI BENCHMARKER ====| ___ ))===="
echo "====| |\/| |======= by torvic9 =======| ___ \====="
echo "====|_|==|_|========   $VER   ========|_____//===="
echo "=================================================="

# start
trap killproc INT
trap exitproc EXIT

runperf ; sleep 2
runpi ; sleep 2
runargon ; sleep 2
runsysb1 ; sleep 2
runsysb2 ; sleep 2
runsysb3 ; sleep 2
runffm ; sync ; sleep 2
rundarkt ; sync ; sleep 2
runxz ; sync ; sleep 2
runblend ; sync ; sleep 2

unset arrayz; unset ARRAY
arrayz=(`awk -F': ' '{print $2}' $LOGFILE`)
# arrayn not used currently
# arrayn=(`awk -F': ' '{print $1}' $LOGFILE`)
# watch!
#set -x
# watch!

for ((i=0 ; i<$(( $NRTESTS - 4)) ; i++)) ; do
	ARRAY[$i]="$(echo "scale=10; (${arrayz[$i]} * 0.1) * sqrt(${arrayz[$i]})" | bc -l)"
done
for ((i=$(( $NRTESTS - 4 )) ; i<$NRTESTS ; i++)) ; do
	ARRAY[$i]="$(echo "scale=10; (${arrayz[$i]} * 0.2) * sqrt(${arrayz[$i]})" | bc -l)"
done

#TTIME="$(echo "${arrayz[@]}" | sed 's/ /+/g' | bc)"
TTIME="$(IFS="+" ; bc <<< "scale=2; ${arrayz[*]}")"
INTSCORE="$(IFS="+" ; bc -l <<< "scale=2; ${ARRAY[*]}")"
SCORE="$(bc -l <<< "scale=2; $INTSCORE * $COEFF / $NRTESTS")"
echo "--------------------------------------------------"
echo "Total time in seconds:"
echo "--------------------------------------------------"
echo $TTIME ; echo "Total time (s): $TTIME" >> $LOGFILE
echo "--------------------------------------------------"
echo "Total score (lower is better):"
echo "--------------------------------------------------"
echo $SCORE ; echo "Total score: $SCORE" >> $LOGFILE
echo $SYSINFO >> $LOGFILE
echo "=================================================="
exit 0
