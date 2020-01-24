#!/bin/bash

[[ ! -d $1 || ! -d $2 ]] && echo "Usage: build-hpl-amd.sh <path-to-build-dir> <path-to-install-dir>" && exit 2
BUILDDIR=$1
INSTDIR=$2
NCORES=`nproc`
cd $BUILDDIR
[[ ! -f openmpi.tar.gz ]] && wget -qO openmpi.tar.gz https://download.open-mpi.org/release/open-mpi/v3.1/openmpi-3.1.5.tar.gz
tar xf openmpi.tar.gz
cd openmpi-3.1.5
CFLAGS="-O3 -march=native -pipe" ./configure --prefix=$INSTDIR/openmpi
make -j${NCORES} && make install
cd ..

cat > $INSTDIR/mpi-env.sh <<- EOF
 export MPI_HOME=$INSTDIR/openmpi
 export PATH=$PATH:$MPI_HOME/bin
 export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$MPI_HOME/lib
 export OMP_PROC_BIND=TRUE
 export OMP_PLACES=cores
 export OMP_NUM_THREADS=2
 export BLIS_NUM_THREADS=2
EOF
source $INSTDIR/mpi-env.sh

[[ ! -f blis21.tar.gz ]] && wget -qO blis21.tar.gz https://github.com/amd/blis/archive/2.1.tar.gz
tar xf blis21.tar.gz
cd blis-2.1
CFLAGS="-O3 -march=native -pipe" ./configure -t openmp --prefix=$INSTDIR/blis auto
make -j${NCORES} && make install
cd ..

[[ ! -f hpl.tar.gz ]] && wget -qO hpl.tar.gz http://www.netlib.org/benchmark/hpl/hpl-2.3.tar.gz
tar xf hpl.tar.gz
cd hpl-2.3
cat > Make.AMD_BLIS <<- EOF
SHELL        = /bin/sh
CD           = cd
CP           = cp
LN_S         = ln -s
MKDIR        = mkdir
RM           = /bin/rm -f
TOUCH        = touch
ARCH         = AMD_BLIS
TOPdir       = BUILDDIR/hpl-2.3
INCdir       = $(TOPdir)/include
BINdir       = $(TOPdir)/bin/$(ARCH)
LIBdir       = $(TOPdir)/lib/$(ARCH)
HPLlib       = $(LIBdir)/libhpl.a
MPdir        = INSTALLDIR/openmpi
MPinc        = -I$(MPdir)/include
MPlib        = $(MPdir)/lib/libmpi.so
LAdir        = INSTALLDIR/blis
LAinc        = $(LAdir)/include/blis
LAlib        = $(LAdir)/lib/libblis-mt.a
F2CDEFS      = -DAdd__ -DF77_INTEGER=int -DStringSunStyle
HPL_INCLUDES = -I$(INCdir) -I$(INCdir)/$(ARCH) $(LAinc) $(MPinc)
HPL_LIBS     = $(HPLlib) $(LAlib) $(MPlib) -lm
HPL_OPTS     = -DHPL_CALL_CBLAS
HPL_DEFS     = $(F2CDEFS) $(HPL_OPTS) $(HPL_INCLUDES)
CC           = /usr/bin/gcc
CCNOOPT      = $(HPL_DEFS)
CCFLAGS      = $(HPL_DEFS) -std=c99 -march=native -fomit-frame-pointer -O3 -pipe -funroll-loops -W -Wall -fopenmp
LINKER       = /usr/bin/gcc
LINKFLAGS    = $(CCFLAGS) -Wl,-O1,-Wl,--as-needed
ARCHIVER     = ar
ARFLAGS      = r
RANLIB       = echo
EOF

BUILDDIR2=$(echo "${BUILDDIR}" | sed -e 's/[]$.*[/^]/\\&/g' )
INSTDIR2=$(echo "${INSTDIR}" | sed -e 's/[]$.*[/^]/\\&/g' )
sed -i "s/BUILDDIR/$BUILDDIR2/g" Make.AMD_BLIS
sed -i "s/INSTALLDIR/$INSTDIR2/g" Make.AMD_BLIS
make arch=AMD_BLIS
cd ..
mkdir $INSTDIR/hpl
cp -a bin/AMD_BLIS/xhpl $INSTDIR/hpl

cat > $INSTDIR/hpl/HPL.dat <<- EOF
HPLinpack benchmark input file
Innovative Computing Laboratory, University of Tennessee
HPL.out      output file name (if any)
6            device out (6=stdout,7=stderr,file)
1            # of problems sizes (N)
25984	     Ns
1            # of NBs
232	     NBs
0            PMAP process mapping (0=Row-,1=Column-major)
1            # of process grids (P x Q)
4            Ps
6            Qs
32.0         threshold
1            # of panel fact
2            PFACTs (0=left, 1=Crout, 2=Right)
1            # of recursive stopping criterium
4            NBMINs (>= 1)
1            # of panels in recursion
2            NDIVs
1            # of recursive panel fact.
2            RFACTs (0=left, 1=Crout, 2=Right)
1            # of broadcast
2            BCASTs (0=1rg,1=1rM,2=2rg,3=2rM,4=Lng,5=LnM)
1            # of lookahead depth
1            DEPTHs (>=0)
1            SWAP (0=bin-exch,1=long,2=mix)
64           swapping threshold
0            L1 in (0=transposed,1=no-transposed) form
0            U  in (0=transposed,1=no-transposed) form
1            Equilibration (0=no,1=yes)
8            memory alignment in double (> 0)
EOF

echo "Finished!"
echo "run command: $INSTDIR/openmpi/bin/mpirun -np 24 --bind-to hwthread --map-by l3cache --mca btl self,vader xhpl

