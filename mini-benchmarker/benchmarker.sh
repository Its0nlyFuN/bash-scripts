#!/bin/bash
# mini-benchmarker
# by torvic9
# contributors and testers:
# Richard Gladman, William Pursell, SGS, mbb, mbod, Manjaro Forum, StackOverflow
# and everyone else I forgot

## tests definitions

runstress1() {
	local RESFILE="$WORKDIR/runstress1"
	/usr/bin/time -f %e -o $RESFILE $STRESS -q $WORKDIR/stressC &>/dev/null &
	local PID=$!
	echo -n -e "* stress-ng cpu arith:\t\t\t"
	local s='-+'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %2 )); printf "\b${s:$i:1}"; sleep 1; done
	printf "\b " ; cat $RESFILE
	echo "stress-ng cpu: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runstress2() {
	local RESFILE="$WORKDIR/runstress2"
	/usr/bin/time -f %e -o $RESFILE $STRESS -q $WORKDIR/stressR &>/dev/null &
	local PID=$!
	echo -n -e "* stress-ng cpu-cache-mem:\t\t"
	local s='-+'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %2 )); printf "\b${s:$i:1}"; sleep 1; done
	printf "\b " ; cat $RESFILE
	echo "stress-ng memory: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runblend() {
	local RESFILE="$WORKDIR/runblend"
	local BLENDER_USER_CONFIG="$WORKDIR"
	/usr/bin/time -f %e -o $RESFILE blender -b $WORKDIR/blender/bmw27_cpu.blend -o $WORKDIR/blenderbmw.png -f 1 --verbose 0 -t 0 &>/dev/null &
	local PID=$!
	echo -n -e "* Blender render:\t\t\t"
	local s='-+'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %2 )); printf "\b${s:$i:1}"; sleep 1; done
	printf "\b " ; cat $RESFILE
	echo "Blender render: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runffm() {
	cd $WORKDIR/ffmpeg-6b6b9e5
	local RESFILE="$WORKDIR/runffm"
	make -s clean &>/dev/null && sleep 1
	/usr/bin/time -f %e -o $RESFILE make -s -j${CPUCORES} &>/dev/null &
	local PID=$!
	echo -n -e "* ffmpeg compilation:\t\t\t"
	local s='-+'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %2 )); printf "\b${s:$i:1}"; sleep 1; done
	printf "\b " ; cat $RESFILE
	echo "ffmpeg compilation: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runxz() {
	local RESFILE="$WORKDIR/runxz"
 	/usr/bin/time -f %e -o $RESFILE xz -z -k -T${CPUCORES} --lzma2=preset=7,pb=0 -Qqq -f $WORKDIR/firefox60.tar &
	local PID=$!
	echo -n -e "* xz compression:\t\t\t"
	local s='-+'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %2 )); printf "\b${s:$i:1}"; sleep 1; done
	printf "\b " ; cat $RESFILE
	echo "xz compression: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runargon() {
	local RESFILE="$WORKDIR/runargon"
	/usr/bin/time -f %e -o $RESFILE argon2 BenchieSalt -id -t 30 -m 21 -p $CPUCORES &>/dev/null <<< $(dd if=/dev/urandom bs=1 count=64 status=none) &
	local PID=$!
	echo -n -e "* argon2 hashing:\t\t\t"
	local s='-+'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %2 )); printf "\b${s:$i:1}"; sleep 1; done
	printf "\b " ; cat $RESFILE
	echo "argon2 hashing: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runperf1() {
	local RESFILE="$WORKDIR/runperf"
	perf bench -f simple sched messaging -p -g 32 -l 10000 1> $RESFILE &
	local PID=$!
	echo -n -e "* perf sched msg:\t\t\t"
	local s='-+'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %2 )); printf "\b${s:$i:1}"; sleep 1; done
	printf "\b " ; cat $RESFILE
	echo "perf sched msg: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runperf2() {
	local RESFILE="$WORKDIR/runperf"
	perf bench -f simple sched pipe -T -l 1500000 1> $RESFILE &
	local PID=$!
	echo -n -e "* perf sched pipe:\t\t\t"
	local s='-+'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %2 )); printf "\b${s:$i:1}"; sleep 1; done
	printf "\b " ; cat $RESFILE
	echo "perf sched pipe: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runperf3() {
	local RESFILE="$WORKDIR/runperf"
	/usr/bin/time -f %e -o $RESFILE perf bench -f simple mem memcpy --nr_loops 100 --size 2GB -f default &>/dev/null &
	local PID=$!
	echo -n -e "* perf memcpy:\t\t\t\t"
	local s='-+'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %2 )); printf "\b${s:$i:1}"; sleep 1; done
	printf "\b " ; cat $RESFILE
	echo "perf memcpy: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

runpi() {
	local RESFILE="$WORKDIR/runpi"
	/usr/bin/time -f%e -o $RESFILE $WORKDIR/pi 50000000 1>/dev/null &
	local PID=$!
	echo -n -e "* calculating 50m digits of pi:\t\t"
	local s='-+'; local i=0; while kill -0 $PID &>/dev/null ; do i=$(( (i+1) %2 )); printf "\b${s:$i:1}"; sleep 1; done
	printf "\b " ; cat $RESFILE
	echo "calculating 50m digits of pi: $(cat $RESFILE)" >> $LOGFILE
	return 0
}

# traps (ctrl-c)
killproc() {
	echo -e "\n*** Received SIGINT, aborting! ***\n"
	kill -- -$$ && exit 2
}

exitproc() {
	echo -e "-> Removing temporary files...\n"
	for i in $WORKDIR/{run*,ffmpeg.tar.gz,stress-ng.tar.xz,firefox60.tar.xz,blender*.png,pi.c,stressC,stressR} ; do
		[[ -f $i ]] && rm $i
		[[ -d $i ]] && rm -r $i
	done
	rm $(echo $LOCKFILE) && echo -e "${TB}Bye!${TN}\n"
}

## main start

# vars
export LANG=C
CURRDIR=`pwd`
WORKDIR="$1"
TMP="/tmp"
VER="v1.4"
CDATE=`date +%F-%H%M`
RAMSIZE=`awk '/MemTotal/{print int($2 / 1000)}' /proc/meminfo`
CPUCORES=`nproc`
CPUGOV=`cat /sys/devices/system/cpu/cpufreq/policy0/scaling_governor`
CPUFREQ=`awk '{print $1 / 1000000}' /sys/devices/system/cpu/cpufreq/policy0/cpuinfo_max_freq`
CPUL3C=`lscpu -C=name,all-size | awk '/L3/{print $2}'`
COEFF=$(echo "scale=4; sqrt(${CPUCORES} / 2 + ${CPUFREQ})" | bc -l)

# I leave this for reference
#CPUFREQ=$(cpupower frequency-info -l | grep -v "analyzing" | awk '{print $2 / 1000000}')
#CPUGOV=$(cpupower frequency-info -o | grep -m1 "^CPU" | awk -F' -  ' '{ print $3 }')
#CPUMHZ=$(lscpu -e=maxmhz | tail -n1)
#CPUGHZ=$(echo "scale=1; ${CPUMHZ%%,*} / 1000" | bc)

# terminal effects
TB=$(tput bold)
TN=$(tput sgr0)
FARBE1="`printf '\033[0;91m'`"
FARBE2="`printf '\033[4;37m'`"
FARBE3="`printf '\033[0;33m'`"

# total number of tests
NRTESTS=10

# system info will be logged
SYSINFO=$(inxi -c0 -v | sed "s/Up:.*//;s/inxi:.*//;s/Storage:.*//")

# path to stress-ng binary
STRESS=${WORKDIR}/stress-ng/usr/bin/stress-ng

# check system and paths
[[ $RAMSIZE -lt 3500 ]] && echo "Your computer must have at least 4 GB of RAM! Aborting." && exit 2
[[ $CPUCORES -lt 2 ]] && echo "Your CPU must have at least two logical or physical cores! Aborting." && exit 2

[[ -z $1 ]] && echo "Please specify the full path for the temporary directory! Aborting." && exit 4

[[ "${WORKDIR:0:1}" != "/" ]] && WORKDIR="$PWD/$WORKDIR"
if [[ ! -d "$WORKDIR" ]] ; then
	read -p "The specified directory ${TB}$WORKDIR${TN} does not exist. Create it (y/N)? " DCHOICE
	[[ $DCHOICE = "y" || $DCHOICE = "Y" ]] && mkdir -p $WORKDIR || exit 4
fi

# results will be written to this file
LOGFILE="$WORKDIR/benchie_${CDATE}.log"
# lockfile has no real purpose here but it's cool
LOCKFILE=`mktemp $WORKDIR/benchie.XXXX`

# allow more open files
ulimit -n 4096

# stress-ng jobfiles
# stressC is CPU arithmetic, stressR is CPU+Cache+RAM
cat > $WORKDIR/stressC <<- EOF
run sequential
sched batch
no-rand-seed
timeout 0
cpu CPUCORES
cpu-method float128
EOF
echo "cpu-ops $((4800 / ${CPUCORES}))" >> $WORKDIR/stressC
cat >> $WORKDIR/stressC <<- EOF
cpu CPUCORES
cpu-method matrixprod
EOF
echo "cpu-ops $((4800 / ${CPUCORES}))" >> $WORKDIR/stressC
cat >> $WORKDIR/stressC <<- EOF
cpu CPUCORES
cpu-method nsqrt
EOF
echo "cpu-ops $((4800 / ${CPUCORES}))" >> $WORKDIR/stressC
cat >> $WORKDIR/stressC <<- EOF
cpu CPUCORES
cpu-method prime
EOF
echo "cpu-ops $((2400 / ${CPUCORES}))" >> $WORKDIR/stressC
cat >> $WORKDIR/stressC <<- EOF
cpu CPUCORES
cpu-method sieve
EOF
echo "cpu-ops $((2400 / ${CPUCORES}))" >> $WORKDIR/stressC
cat >> $WORKDIR/stressC <<- EOF
cpu CPUCORES
cpu-method queens
EOF
echo "cpu-ops $((2400 / ${CPUCORES}))" >> $WORKDIR/stressC
cat >> $WORKDIR/stressC <<- EOF
crypt CPUCORES
EOF
echo "crypt-ops $((2400 / ${CPUCORES}))" >> $WORKDIR/stressC

cat > $WORKDIR/stressR <<- EOF
run sequential
timeout 0
sched batch
no-rand-seed
page-in
verify
vm CPUCORES
vm-method incdec
vm-bytes 2g
EOF
echo "vm-ops $((12000 / ${CPUCORES}))" >> $WORKDIR/stressR
cat >> $WORKDIR/stressR <<- EOF
vm-addr CPUCORES
vm-addr-method pwr2
EOF
echo "vm-addr-ops $((2400 / ${CPUCORES}))" >> $WORKDIR/stressR
cat >> $WORKDIR/stressR <<- EOF
mmap CPUCORES
mmap-bytes 128m
EOF
echo "mmap-ops $((2400 / ${CPUCORES}))" >> $WORKDIR/stressR
cat >> $WORKDIR/stressR <<- EOF
stream CPUCORES
stream-index 0
stream-l3-size CPUL3C
stream-madvise nohugepage
EOF
echo "stream-ops $((2400 / ${CPUCORES}))" >> $WORKDIR/stressR
cat >> $WORKDIR/stressR <<- EOF
bsearch CPUCORES
bsearch-size 131072
EOF
echo "bsearch-ops $((2400 / ${CPUCORES}))" >> $WORKDIR/stressR
cat >> $WORKDIR/stressC <<- EOF
mergesort CPUCORES
mergesort-size 131072
EOF
echo "mergesort-ops $((2400 / ${CPUCORES}))" >> $WORKDIR/stressC

sed -i "s/CPUCORES/$CPUCORES/g" $WORKDIR/stressC
sed -i "s/CPUCORES/$CPUCORES/g;s/CPUL3C/$CPUL3C/g" $WORKDIR/stressR

# intro text and explanation
echo -e "\n${FARBE1}MINI-BENCHMARKER: This script can take more than 30m on slow computers!${TN}\n"
echo -e "${FARBE2}${TB}Explanation notes${TN}:\n"
echo -e "${FARBE3}${TB}stress-ng cpu arith${TN} measures typical FPU math scenarios like"
echo -e "prime numbers, Erastothenes' sieve, matrices and the Queens problem.\n"
echo -e "${FARBE3}${TB}stress-ng cpu-cache-mem${TN} measures the vm, memory and cache interfaces"
echo -e "less focussed on raw cpu performance.\n"
echo -e "The ${FARBE3}${TB}perf sched${TN} benchmarks concentrate on interprocess communication"
echo -e "and pipelining, whereas the ${FARBE3}${TB}perf mem${TN} benchmark tries to measure"
echo -e "raw RAM speed with the libc memcpy function.\n"
echo -e "The ${FARBE3}${TB}pi calculation${TN} is single-threaded.\n"
echo -e "${FARBE3}${TB}argon2${TN} is a prized hashing algorithm. Here, we use 30 iterations with"
echo -e "2G of memory being used, with a fixed salt and a random password.\n"
echo -e "What follows are three 'real world' benchmarks, measuring ${FARBE3}${TB}compilation"
echo -e "of ffmpeg${TN}, ${FARBE3}${TB}xz compression${TN} level 7, and the famous ${FARBE3}${TB}Blender${TN} BMW rendering.\n"
echo -e "The ${FARBE3}${TB}score${TN} is not really relevant. It tries to compress the pure"
echo -e "time results. What counts is total time."
echo -e "The Blender rendering has a lower weighting, because it takes a lot of"
echo -e "time even on fast CPUs. ${TB}No GPU acceleration.${TN}\n"
echo -e "You should ${FARBE3}${TB}run this script in runlevel 3${TN}, on Linux distros with systemd,"
echo -e "either append a '3' to the boot command line, or issue"
echo -e "'systemctl isolate multi-user'.\n"

#read -p "Do you want to drop page cache now? Root priviledges needed! (y/N) " DCHOICE
#[[ $DCHOICE = "y" || $DCHOICE = "Y" ]] && su -c "echo 3 > /proc/sys/vm/drop_caches"

# ask user for permission to choose performance gov
if [[ $CPUGOV != "performance" ]] ; then
	read -p "You should use the ${TB}performance${TN} cpufreq governor, enable now? (y/N) " DCHOICE
	[[ $DCHOICE = "y" || $DCHOICE = "Y" ]] && su -c "cpupower frequency-set -g performance &>/dev/null"
fi

# the echo command below explaines it all
echo -e "\n${TB}Checking, downloading and preparing test files...${TN}"

if [[ ! -f $WORKDIR/firefox60.tar ]]; then
	wget --show-progress -qO $WORKDIR/firefox60.tar.xz https://ftp.mozilla.org/pub/firefox/releases/60.9.0esr/source/firefox-60.9.0esr.source.tar.xz
	echo "-> Unzipping Firefox tarball..."
	xz -d -q $WORKDIR/firefox60.tar.xz
fi

if [[ ! -f $WORKDIR/pi ]] ; then
	wget --show-progress -qO $WORKDIR/pi.c https://gmplib.org/download/misc/gmp-chudnovsky.c
	echo "-> Compiling pi source file..."
	gcc -O3 -march=native $WORKDIR/pi.c -o $WORKDIR/pi -lm -lgmp
	rm $WORKDIR/pi.c
fi

if [[ ! -d $WORKDIR/stress-ng ]]; then
	wget --show-progress -qO $WORKDIR/stress-ng.tar.xz https://kernel.ubuntu.com/~cking/tarballs/stress-ng/stress-ng-0.11.24.tar.xz
	echo "-> Preparing stress-ng..."
	cd $WORKDIR
	tar xf stress-ng.tar.xz
	cd stress-ng-0.11.24
	sed -i 's/\-O2/\-O2\ \-march\=native/' Makefile
	make -s -j${CPUCORES} &>/dev/null && make -s DESTDIR=$WORKDIR/stress-ng install &>/dev/null
	cd .. && rm -rf stress-ng-0.11.24
fi

if [[ ! -d $WORKDIR/blender ]]; then
	wget --show-progress -qO $WORKDIR/blender.zip https://download.blender.org/demo/test/BMW27_2.blend.zip
	echo "-> Unzipping Blender demo files..."
	unzip -qqj $WORKDIR/blender.zip -d $WORKDIR/blender
fi

if [[ ! -d $WORKDIR/ffmpeg-6b6b9e5 ]]; then
	wget --show-progress -qO $WORKDIR/ffmpeg.tar.gz https://git.ffmpeg.org/gitweb/ffmpeg.git/snapshot/6b6b9e593dd4d3aaf75f48d40a13ef03bdef9fdb.tar.gz
	echo "-> Preparing ffmpeg..."
	cd $WORKDIR
	tar xf ffmpeg.tar.gz
	cd ffmpeg-6b6b9e5
	./configure --prefix=/tmp --disable-debug --enable-static --enable-version3 \
  	  --enable-gpl --disable-programs --disable-ffplay --disable-ffprobe \
  	  --disable-doc --disable-network --disable-protocols --disable-lzma --disable-openssl \
  	  --disable-amf --disable-cuda-llvm --disable-cuvid --disable-d3d11va --disable-dxva2 \
  	  --disable-nvdec --disable-nvenc --disable-vaapi --disable-vdpau --disable-sdl2 \
  	  --disable-schannel --disable-sndio --disable-securetransport --disable-libfontconfig \
  	  --disable-libfreetype --enable-gmp --enable-libvorbis --enable-libdav1d \
  	  --enable-libx264 --enable-libx265 --disable-libvpx --enable-opengl --enable-libdrm \
  	  --disable-autodetect &>/dev/null
fi

# here we go
echo -e "\n${TB}Starting...${TN}\n" ; sync ; sleep 2

echo -e "__________________________________________________"
echo -e "=====${TB}__${TN}==${TB}__${TN} ===========================${TB}_____${TN} ====="
echo -e "====${TB}|  \/  |${TN}==== MINI BENCHMARKER ====${TB}| ___ ))${TN}===="
echo -e "====${TB}| |\/| |${TN}======= by torvic9 =======${TB}| ___ \\${TN}====="
echo -e "====${TB}|_|${TN}==${TB}|_|${TN}=========  $VER  =========${TB}|_____//${TN}===="
echo -e "==================================================\n"

# traps (ctrl-c)
trap killproc INT
trap exitproc EXIT

# run
runstress1 ; sleep 3
runstress2 ; sleep 3
runperf1 ; sleep 3
runperf2 ; sleep 3
runperf3 ; sleep 3
runpi ; sleep 3
runargon ; sleep 3
runffm ; sleep 3
runxz ; sleep 3
runblend ; sleep 3

# time and score calculations, print and log final results
unset arraytime ; unset ARRAY
NRTESTSMIN=$(( ${NRTESTS} - 1))
arraytime=(`awk -F': ' '{print $2}' $LOGFILE`)

for ((i=0 ; i<${NRTESTSMIN} ; i++)) ; do
	ARRAY[$i]="$(echo "scale=4; ${arraytime[$i]} * $COEFF / 1.62" | bc -l)"
done

# last test is blender which takes more time, use higher divider
ARRAY[${NRTESTSMIN}]="$(echo "scale=4; ${arraytime[${NRTESTSMIN}]} * $COEFF / 2.43" | bc -l)"

TOTTIME="$(IFS="+" ; bc <<< "scale=2; ${arraytime[*]}")"
INTSCORE="$(IFS="+" ; bc -l <<< "scale=4; ${ARRAY[*]}")"
SCORE="$(bc -l <<< "scale=2; $INTSCORE / $NRTESTS")"

echo "--------------------------------------------------"
echo "Total time in seconds:"
echo "--------------------------------------------------"
echo "  ${TB}$TOTTIME${TN}" ; echo "Total time (s): $TOTTIME" >> $LOGFILE
echo "--------------------------------------------------"
echo "Total score (lower is better)" ; echo " [multi = $COEFF]:"
echo "--------------------------------------------------"
echo "  ${TB}$SCORE${TN}" ; echo "Total score: $SCORE" >> $LOGFILE
echo $SYSINFO >> $LOGFILE
echo "=================================================="

exit 0

