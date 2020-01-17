#!/bin/bash
# by torvic9
# Contributors and testers:
# Richard Gladman, William Pursell, SGS, mbb, mbod, Manjaro Forum, StackOverflow

runstress1() {
	local RESFILE="$WORKDIR/runstress1"
	/usr/bin/time -f %e -o $RESFILE $STRESS -q --matrix-3d $CPUCORES --matrix-3d-method trans --matrix-3d-size 128 --matrix-3d-ops 5000 &>/dev/null &
	local PID=$!
	echo -n -e "* stress-ng matrix3d:\t\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep 1; done
	printf "\b " ; cat $RESFILE
	echo "stress-ng matrix3d: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runstress2() {
	local RESFILE="$WORKDIR/runstress2"
	/usr/bin/time -f %e -o $RESFILE $STRESS -q --vm $CPUCORES --vm-method rowhammer --vm-populate --vm-bytes 1G --vm-ops 20000 &>/dev/null &
	local PID=$!
	echo -n -e "* stress-ng rowhammer:\t\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep 1; done
	printf "\b " ; cat $RESFILE
	echo "stress-ng rowhammer: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runstress3() {
	local RESFILE="$WORKDIR/runstress3"
	/usr/bin/time -f %e -o $RESFILE $STRESS -q --mmap $CPUCORES --mmap-bytes 128M --mmap-ops 10 --mmap-file &>/dev/null &
	local PID=$!
	echo -n -e "* stress-ng mmap:\t\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep 1; done
	printf "\b " ; cat $RESFILE
	echo "stress-ng mmap: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runffm() {
	cd $WORKDIR/ffmpeg-1529dfb
	local RESFILE="$WORKDIR/runffm"
	/usr/bin/time -f %e -o $RESFILE make -s -j${CPUCORES} &>/dev/null &
	local PID=$!
	echo -n -e "* ffmpeg compilation:\t\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep 1; done
	printf "\b " ; cat $RESFILE
	echo "ffmpeg compilation: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runxz() {
	local RESFILE="$WORKDIR/runxz"
 	/usr/bin/time -f %e -o $RESFILE xz -z -k -T${CPUCORES} --lzma2=preset=7e,pb=0 -Qqq -f $WORKDIR/kernel49.tar &
	local PID=$!
	echo -n -e "* xz compression:\t\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep 1; done
	printf "\b " ; cat $RESFILE
	echo "xz compression: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runargon() {
	local RESFILE="$WORKDIR/runargon"
	/usr/bin/time -f %e -o $RESFILE argon2 BenchieSalt -i -t 60 -m 20 -p $CPUCORES &>/dev/null <<< $(dd if=/dev/urandom bs=1 count=64 status=none) &
	local PID=$!
	echo -n -e "* argon2 hashing:\t\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep 1; done
	printf "\b " ; cat $RESFILE
	echo "argon2 hashing: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runperf1() {
	local RESFILE="$WORKDIR/runperf"
	perf bench -f simple sched messaging -p -t -g 25 -l 10000 1> $RESFILE &
	local PID=$!
	echo -n -e "* perf sched:\t\t\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep 1; done
	printf "\b " ; cat $RESFILE
	echo "perf sched: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runperf2() {
	local RESFILE="$WORKDIR/runperf"
	/usr/bin/time -f %e -o $RESFILE perf bench -f simple mem memcpy --nr_loops 50 --size 2GB -f x86-64-movsb &>/dev/null &
	local PID=$!
	echo -n -e "* perf memcpy:\t\t\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep 1; done
	printf "\b " ; cat $RESFILE
	echo "perf memcpy: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runpi() {
	local RESFILE="$WORKDIR/runpi"
	/usr/bin/time -f%e -o $RESFILE $WORKDIR/pi 66000000 1>/dev/null &
	local PID=$!
	echo -n -e "* calculating 66m digits of pi:\t\t"
	local s='-\|/'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %4 )); printf "\b${s:$i:1}"; sleep 1; done
	printf "\b " ; cat $RESFILE
	echo "calculating 66m digits of pi: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

killproc() {
	echo -e "\n*** Received SIGINT, aborting! ***\n"
	kill -- -$$ && exit 2
}

exitproc() {
	echo -e "Removing temporary files...\n"
	for i in $WORKDIR/{run*,ffmpeg-1529dfb,pi} ; do
		[[ -f $i ]] && rm $i
		[[ -d $i ]] && rm -r $i
	done
	rm $(echo $LOCKFILE)
}

export LANG=C
CURRDIR=`pwd`
WORKDIR="$1"
VER="v1.0"
CDATE=`date +%F-%H%M`
RAMSIZE=`awk '/MemTotal/{print int($2 / 1000)}' /proc/meminfo`
CPUCORES=`nproc`
CPUGOV=`cat /sys/devices/system/cpu/cpufreq/policy0/scaling_governor`
CPUFREQ=`awk '{print $1 / 1000000}' /sys/devices/system/cpu/cpufreq/policy0/cpuinfo_max_freq`
COEFF=$(echo "scale=2; l(${CPUCORES} / 2 + ${CPUFREQ})" | bc -l)
NRTESTS=9
SYSINFO=$(inxi -c0 -v | sed "s/Up:.*//;s/inxi:.*//;s/Storage:.*//")
STRESS=${WORKDIR}/stress-ng/usr/bin/stress-ng

# I leave this for reference
#CPUFREQ=$(cpupower frequency-info -l | grep -v "analyzing" | awk '{print $2 / 1000000}')
#CPUGOV=$(cpupower frequency-info -o | grep -m1 "^CPU" | awk -F' -  ' '{ print $3 }')
#CPUMHZ=$(lscpu -e=maxmhz | tail -n1)
#CPUGHZ=$(echo "scale=1; ${CPUMHZ%%,*} / 1000" | bc)

[[ $RAMSIZE -lt 3500 ]] && echo "Your computer must have at least 4 GB of RAM! Aborting." && exit 2

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

if [[ ! -f $WORKDIR/kernel49.tar ]]; then
	wget --show-progress -qO $WORKDIR/kernel49.tar.xz https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.9.tar.xz
	echo "Unzipping kernel tarball..."
	xz -d -q $WORKDIR/kernel49.tar.xz
fi

if [[ ! -d $WORKDIR/stress-ng ]]; then
	wget --show-progress -qO $WORKDIR/stress-ng.tar.xz https://kernel.ubuntu.com/~cking/tarballs/stress-ng/stress-ng-0.10.15.tar.xz
	echo "Preparing stress-ng..."
	cd $WORKDIR
	tar xf stress-ng.tar.xz
	cd stress-ng-0.10.15
	sed -i 's/\-O2/\-O2\ \-march\=native/' Makefile
	make -s -j${CPUCORES} && make -s DESTDIR=$WORKDIR/stress-ng install
	cd .. && rm -rf stress-ng-0.10.15
fi

if [[ ! -f $WORKDIR/ffmpeg.tar.gz ]]; then
	wget --show-progress -qO $WORKDIR/ffmpeg.tar.gz https://git.ffmpeg.org/gitweb/ffmpeg.git/snapshot/1529dfb73a5157dcb8762051ec4c8d8341762478.tar.gz
fi
echo "Preparing ffmpeg..."
cd $WORKDIR
tar xf ffmpeg.tar.gz
cd ffmpeg-1529dfb
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
cd $CURRDIR

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
runstress1; sleep 3
runstress2; sleep 3
runstress3; sleep 3
runperf1 ; sleep 3
runperf2 ; sleep 3
runpi ; sleep 3
runargon ; sleep 3
runffm ; sync ; sleep 3
runxz ; sync ; sleep 3

unset arrayz; unset ARRAY
arrayz=(`awk -F': ' '{print $2}' $LOGFILE`)
# arrayn not used currently
# arrayn=(`awk -F': ' '{print $1}' $LOGFILE`)
# watch!
#set -x
# watch!

for ((i=0 ; i<${NRTESTS} ; i++)) ; do
	ARRAY[$i]="$(echo "scale=10; ${arrayz[$i]} * sqrt(${arrayz[$i]})" | bc -l)"
done

#TTIME="$(echo "${arrayz[@]}" | sed 's/ /+/g' | bc)"
TTIME="$(IFS="+" ; bc <<< "scale=2; ${arrayz[*]}")"
INTSCORE="$(IFS="+" ; bc -l <<< "scale=2; ${ARRAY[*]}")"
SCORE="$(bc -l <<< "scale=0; $INTSCORE * $COEFF / $NRTESTS")"
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

