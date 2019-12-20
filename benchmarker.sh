#!/bin/bash
# by torvic9
# Contributors and testers:
# Richard Gladman, William Pursell, SGS, mbb, mbod, Manjaro Forum, StackOverflow

runffm() {
	cd $WORKDIR
	cd ffmpeg-1529dfb
	local RESFILE="$WORKDIR/runffm"
	/usr/bin/time -f %e -o $RESFILE make -s -j${CPUCORES} &>/dev/null &
	local PID=$!
	echo -n -e "\n* ffmpeg compilation:\t\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep .5; done
	printf "\b " ; cat $RESFILE
	echo "ffmpeg compilation: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runxz() {
	local RESFILE="$WORKDIR/runxz"
 	/usr/bin/time -f %e -o $RESFILE xz -z -T${CPUCORES} --lzma2=preset=6e,pb=0 -Qqq -f $WORKDIR/kernel49.tar &
	local PID=$!
	echo -n -e "* XZ compression:\t\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep .5; done
	printf "\b " ; cat $RESFILE
	echo "XZ compression: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runblend() {
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

runperf1() {
	local RESFILE="$WORKDIR/runperf"
	perf bench -f simple sched messaging -p -t -g 25 -l 10000 1> $RESFILE &
	local PID=$!
	echo -n -e "* Perf sched:\t\t\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep 1; done
	printf "\b " ; cat $RESFILE
	echo "Perf sched: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runperf2() {
	local RESFILE="$WORKDIR/runperf"
	/usr/bin/time -f %e -o $RESFILE perf bench -f simple mem memset --nr_loops 100 --size 1GB -f default &>/dev/null &
	local PID=$!
	echo -n -e "* Perf memset:\t\t\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep 1; done
	printf "\b " ; cat $RESFILE
	echo "Perf sched: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runpi() {
	local RESFILE="$WORKDIR/runpi"
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

#runsysb2() {
#	local RESFILE="$WORKDIR/runsysb2"
# 	/usr/bin/time -f %e -o $RESFILE sysbench --threads=$CPUCORES --verbosity=0 --time=0 \
# 	memory run --memory-total-size=128G --memory-block-size=4K --memory-oper=write --memory-access-mode=seq &>/dev/null &
#	local PID=$!
#	echo -n -e "* Sysbench RAM write:\t\t\t"
#	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep .5; done
#	printf "\b " ; cat $RESFILE
#	echo "Sysbench RAM write: $(cat $RESFILE)" >> $LOGFILE
#	return 0
#}

runsysb2() {
	local RESFILE="$WORKDIR/runsysb2"
 	/usr/bin/time -f %e -o $RESFILE sysbench --threads=$CPUCORES --verbosity=0 --time=0 \
 	memory run --memory-total-size=150G --memory-block-size=1K --memory-oper=read --memory-access-mode=rnd &>/dev/null &
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
CURRDIR=`pwd`
WORKDIR="$1"
VER="v1.0"
CDATE=`date +%F-%H%M`
RAMSIZE=`awk '/MemTotal/{print int($2 / 1000000)}' /proc/meminfo`
CPUCORES=`nproc`
CPUGOV=`cat /sys/devices/system/cpu/cpufreq/policy0/scaling_governor`
CPUFREQ=`awk '{print $1 / 1000000}' /sys/devices/system/cpu/cpufreq/policy0/cpuinfo_max_freq`
COEFF=$(echo "scale=2; l(${CPUCORES} / 2 + ${CPUFREQ})" | bc -l)
NRTESTS=10
SYSINFO=$(inxi -c0 -v | sed "s/Up:.*//;s/inxi:.*//;s/Storage:.*//")

# I leave this for reference
#CPUFREQ=$(cpupower frequency-info -l | grep -v "analyzing" | awk '{print $2 / 1000000}')
#CPUGOV=$(cpupower frequency-info -o | grep -m1 "^CPU" | awk -F' -  ' '{ print $3 }')
#CPUMHZ=$(lscpu -e=maxmhz | tail -n1)
#CPUGHZ=$(echo "scale=1; ${CPUMHZ%%,*} / 1000" | bc)

[[ $RAMSIZE -lt 4 ]] && echo "Your computer must have at least 4 GB of RAM! Aborting." && exit 2

[[ -z $1 ]] && echo "Please specify the full path for the temporary directory! Aborting." && exit 4

[[ "${WORKDIR:0:1}" != "/" ]] && WORKDIR="$PWD/$WORKDIR"
if [[ ! -d "$WORKDIR" ]] ; then
	read -p "The specified directory $WORKDIR does not exist. Create it (y/N)? " DCHOICE
	[[ $DCHOICE = "y" || $DCHOICE = "Y" ]] && mkdir -p $WORKDIR || exit 4
fi

LOGFILE="$WORKDIR/benchie_${CDATE}.log"
LOCKFILE=`mktemp $WORKDIR/benchie.XXXX`

read -p "Do you want to drop page cache now? Root priviledges needed! (y/N)" DCHOICE
[[ $DCHOICE = "y" || $DCHOICE = "Y" ]] && su -c "echo 3 > /proc/sys/vm/drop_caches"

if [[ $CPUGOV != "performance" ]] ; then
	read -p "You should use the 'performance' cpufreq governor, enable now? (y/N)" DCHOICE
	[[ $DCHOICE = "y" || $DCHOICE = "Y" ]] && su -c "cpupower frequency-set -g performance"
fi

echo -e "\nChecking, downloading and preparing test files...\n"

if [[ ! -f $WORKDIR/bench.srw && ! -f $WORKDIR/bench.srw.xmp ]]; then
 	wget --show-progress -qO $WORKDIR/bench.srw http://www.mirada.ch/bench.SRW
 	wget --show-progress -qO $WORKDIR/bench.srw.xmp http://www.mirada.ch/bench.SRW.xmp
fi

if [[ ! -f $WORKDIR/kernel49.tar.xz ]]; then
	wget --show-progress -qO $WORKDIR/kernel49.tar.xz https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.9.tar.xz
fi
echo "Unzipping kernel tarball..."
xz -d -k -q $WORKDIR/kernel49.tar.xz

if [[ ! -f $WORKDIR/ffmpeg.tar.gz ]]; then
	wget --show-progress -qO $WORKDIR/ffmpeg.tar.gz https://git.ffmpeg.org/gitweb/ffmpeg.git/snapshot/1529dfb73a5157dcb8762051ec4c8d8341762478.tar.gz
fi
echo "Preparing ffmpeg..."
cd $WORKDIR
tar xf ffmpeg.tar.gz
cd ffmpeg-1529dfb
./configure --prefix=/tmp --disable-debug --enable-shared --enable-stripping \
  --disable-ladspa --disable-programs --disable-ffplay --disable-ffprobe \
  --disable-doc --disable-network --disable-protocols --disable-lzma \
  --disable-amf --disable-cuda-llvm --disable-cuvid --disable-d3d11va --disable-dxva2 \
  --disable-nvdec --disable-nvenc --disable-vaapi --disable-vdpau --disable-sdl2 \
  --disable-schannel --disable-securetransport --enable-libfontconfig \
  --enable-libfreetype --enable-libspeex --enable-libvpx --enable-libopus --enable-libvorbis \
  --enable-libx264 --enable-libx265 --enable-opengl --enable-libdrm --enable-gpl \
  --enable-gmp --enable-gnutls --disable-avx512 --disable-fma4 --disable-autodetect \
  --enable-version3 &>/dev/null
cd $CURRDIR

if [[ ! -f $WORKDIR/blender.zip ]]; then
	wget --show-progress -qO $WORKDIR/blender.zip https://download.blender.org/demo/test/Demo_274.zip
fi
echo "Unzipping Blender demo files..."
unzip -qqj $WORKDIR/blender.zip -d $WORKDIR/blender

if [[ ! -f $WORKDIR/pi.c ]]; then
	wget --show-progress -qO $WORKDIR/pi.c https://gmplib.org/download/misc/gmp-chudnovsky.c
fi
echo "Compiling pi source file..."
gcc -O3 -march=native $WORKDIR/pi.c -o $WORKDIR/pi -lm -lgmp

echo -e "Starting...\n" ; sync ; sleep 1
echo "=====__==__ ========================== _____======"
echo "====|  \/  |==== MINI BENCHMARKER ====| ___ ))===="
echo "====| |\/| |======= by torvic9 =======| ___ \====="
echo "====|_|==|_|========   $VER   ========|_____//===="
echo "=================================================="

# start
trap killproc INT
trap exitproc EXIT

runperf1 ; sleep 3
runperf2 ; sleep 3
runpi ; sleep 3
runargon ; sleep 3
runsysb1 ; sleep 3
runsysb2 ; sleep 3
runffm ; sync ; sleep 3
rundarkt ; sync ; sleep 3
runxz ; sync ; sleep 3
runblend ; sync ; sleep 3

unset arrayz; unset ARRAY
arrayz=(`awk -F': ' '{print $2}' $LOGFILE`)
# arrayn not used currently
# arrayn=(`awk -F': ' '{print $1}' $LOGFILE`)
# watch!
#set -x
# watch!

for ((i=0 ; i<$(( $NRTESTS - 4)) ; i++)) ; do
	ARRAY[$i]="$(echo "scale=10; ${arrayz[$i]} * sqrt(${arrayz[$i]} * 1.0)" | bc -l)"
done
for ((i=$(( $NRTESTS - 4 )) ; i<$NRTESTS ; i++)) ; do
	ARRAY[$i]="$(echo "scale=10; ${arrayz[$i]} * sqrt(${arrayz[$i]} * 1.2)" | bc -l)"
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
#echo "Total score (lower is better):"
echo -n "Total score (lower is better)" ; echo " [multi = $COEFF]:"
echo "--------------------------------------------------"
echo $SCORE ; echo "Total score: $SCORE" >> $LOGFILE
echo $SYSINFO >> $LOGFILE
echo "=================================================="
exit 0

