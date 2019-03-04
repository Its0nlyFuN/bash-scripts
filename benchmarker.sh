#!/bin/bash
# torvic9
# v0.1

LANG=C
CDATE=`date +%F-%H%M`
TMPDIR="$1"
LOGFILE="$TMPDIR/benchie_${CDATE}.log"
RAMSIZE=`awk '/MemAvailable/{print $2}' /proc/meminfo`

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

if [[ ! -f /usr/bin/perf || ! -f /usr/bin/unzip || ! -f /usr/bin/darktable-cli || ! -f /usr/bin/sysbench || ! -f /usr/bin/nasm || ! -f /usr/bin/make || ! -f /usr/bin/time} ]] ; then
	echo "Some needed applications are not installed!"
	read -p "Install required packages (y/n)? " UCHOICE
	if [[ $UCHOICE = "y" ]] ; then
		sudo pacman -S nasm perf darktable sysbench time unzip make
	else
		exit 1
	fi
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

echo "====== MINI BENCHMARKER ======"
echo "======      torvic9     ======"
echo "------------------------------"

runffm() {
	cd $TMPDIR
	tar xf ffmpeg.tar.bz2
	cd ffmpeg-4.1
	./configure --quiet --disable-debug --enable-static --enable-gpl --disable-nvdec --disable-nvenc --disable-ffnvcodec --disable-vaapi --disable-vdpau --disable-doc --disable-appkit --disable-avfoundation --disable-sndio --disable-schannel --disable-securetransport --disable-amf --disable-cuvid  --disable-d3d11va --disable-dxva2
	local START=`/usr/bin/time -f %e -o $TMPDIR/runffm make -s -j$(nproc) &>/dev/null`
	cd .. && rm -rf ffmpeg-4.1/
}

runxz() {
	cd $TMPDIR
 	unzip silesia.zip -d silesia/
 	tar cf silesia.tar silesia/
 	rm -rf silesia/
 	local START=`/usr/bin/time -f %e -o $TMPDIR/runxz xz -z -T$(nproc) -7 -Qq $TMPDIR/silesia.tar`
	rm *.xz
}

runperf() {
	cd $TMPDIR
	local START=`perf bench -f simple sched messaging -p -t -g 25 -l 10000`
	echo "$START"
}

runpi() {
	cd $TMPDIR
	local START=`/usr/bin/time -f%e -o $TMPDIR/runpi bc -l -q <<< "scale=6666; 4*a(1)" 1>/dev/null` 
}

rundarkt() {
	cd $TMPDIR
 	local START=`darktable-cli $TMPDIR/bench.srw benchtest_$CDATE.jpg --core --disable-opencl -d perf 2>/dev/null | awk '/dev_process_export/{print $1}'`
 	echo "$START"
}

runsysb1() {
	cd $TMPDIR
 	local START=`/usr/bin/time -f %e -o $TMPDIR/runsysb1 sysbench --threads=$(nproc) --verbosity=0 --events=30000 --time=0 cpu run --cpu-max-prime=30000`
}
runsysb2() {
	cd $TMPDIR
 	local START=`/usr/bin/time -f %e -o $TMPDIR/runsysb2 sysbench --threads=$(nproc) --verbosity=0 --time=0 memory run --memory-total-size=64G --memory-block-size=4K --memory-access-mode=rnd`
}

echo "Running..."
cd $TMPDIR
START="$(runperf)" ; sleep 2
echo "Perf sched: $START" > $LOGFILE
START="$(runpi)" ; sleep 2
echo "Calculating 6666 digits of pi: $(cat $TMPDIR/runpi)" >> $LOGFILE
START="$(runsysb1)" ; sleep 2
echo "SysBench CPU: $(cat $TMPDIR/runsysb1)" >> $LOGFILE
START="$(runsysb2)" ; sleep 2
echo "SysBench random memory: $(cat $TMPDIR/runsysb2)" >> $LOGFILE
START="$(runxz)" ; sleep 2
echo "XZ compression: $(cat $TMPDIR/runxz)" >> $LOGFILE
START="$(runffm)" ; sleep 2
echo "FFmpeg compilation: $(cat $TMPDIR/runffm)" >> $LOGFILE

if [[ $RAMSIZE > 3000000 ]] ; then
	START="$(rundarkt)" ; sleep 2
	echo "Darktable RAW conversion: $START" | sed -n -e 's/,/./p' - >> $LOGFILE
else
	echo "Darktable needs at least 3 GB of available RAM, aborting."
	exit 1
fi

unset arrayn; unset arrayz; unset ARRAY
arrayn=(`awk -F': ' '{print $1}' $LOGFILE`)
arrayz=(`awk -F': ' '{print $2}' $LOGFILE`)

echo "------------------------------"
cat $LOGFILE

for ((i=0 ; i<=6 ; i++)) ; do
	ARRAY[$i]="$(echo "scale=3; sqrt(${arrayz[$i]}*12)" | bc -l)"
done

echo "------------------------------"
echo "Total score (lower is better):"
echo "------------------------------"
echo "${ARRAY[@]}" | sed 's/ /+/g' | bc
echo "=============================="
rm $TMPDIR/{runpi,runsysb1,runsysb2,runxz,runffm}
exit 0

