#!/bin/bash

# basic script to build pgo clang
# needs manual adjustments
# single argument is a full path to store all build files
# torvic9

[[ -z $1 ]] && echo "specify full path for build files!" && exit 4
TOPLEV=$1
PKGVER="10.0.0rc3"
NCORES=`nproc`
export CFLAGS="-O3 -march=native -pipe"
export CXXFLAGS="-O3 -march=native -pipe"
#export LDFLAGS="--as-needed,-z,relro,-z,now"
COMMONFLAGS="-DLLVM_LINK_LLVM_DYLIB=ON -DLLVM_ENABLE_RTTI=ON -DLLVM_ENABLE_FFI=ON \
-DLLVM_ENABLE_SPHINX=OFF -DLLVM_ENABLE_DOXYGEN=OFF -DCMAKE_BUILD_TYPE=Release \
-DFFI_INCLUDE_DIR=$(pkg-config --variable=includedir libffi) \
-DLLVM_BINUTILS_INCDIR=/usr/include -DLLVM_TARGETS_TO_BUILD=X86 \
-DLLVM_PARALLEL_COMPILE_JOBS=${NCORES} -DLLVM_PARALLEL_LINK_JOBS=${NCORES} \
-DLLVM_ENABLE_BINDINGS=OFF"

[[ ! -d $TOPLEV ]] && mkdir $TOPLEV
#cd $TOPLEV
#if [[ ! -d llvm ]]; then
#	git clone --depth=1 --branch=release_100 https://git.llvm.org/git/llvm.git/ llvm
#	cd llvm/tools
#	git clone --depth=1 --branch=release_100 https://git.llvm.org/git/clang.git/
#	cd ../projects
#	git clone --depth=1 --branch=release_100 https://git.llvm.org/git/lld.git/
#	git clone --depth=1 --branch=release_100 https://git.llvm.org/git/compiler-rt.git
#fi

cd $TOPLEV
if [[ ! -d llvm-${PKGVER}.src ]] ; then
	wget -qO llvm.tar.xz --show-progress https://github.com/llvm/llvm-project/releases/download/llvmorg-10.0.0-rc3/llvm-${PKGVER}.src.tar.xz
	tar xf llvm.tar.xz && rm llvm.tar.xz
	cd llvm-${PKGVER}.src/tools
	wget -qO clang.tar.xz --show-progress https://github.com/llvm/llvm-project/releases/download/llvmorg-10.0.0-rc3/clang-${PKGVER}.src.tar.xz
	tar xf clang.tar.xz && rm clang.tar.xz
	cd ../projects
	wget -qO lld.tar.xz --show-progress https://github.com/llvm/llvm-project/releases/download/llvmorg-10.0.0-rc3/lld-${PKGVER}.src.tar.xz
	wget -qO compiler-rt.tar.xz --show-progress https://github.com/llvm/llvm-project/releases/download/llvmorg-10.0.0-rc3/compiler-rt-${PKGVER}.src.tar.xz
	tar xf lld.tar.xz && rm lld.tar.xz
	tar xf compiler-rt.tar.xz && rm compiler-rt.tar.xz
fi

if [[ ! -d $TOPLEV/stage1 ]] ; then
	mkdir $TOPLEV/stage1
fi
cd $TOPLEV/stage1
ninja clean
cmake -G Ninja "$TOPLEV/llvm-${PKGVER}.src" -DCMAKE_C_COMPILER=/usr/bin/gcc \
-DCMAKE_CXX_COMPILER=/usr/bin/g++ -DCMAKE_INSTALL_PREFIX="$TOPLEV/stage1/install" ${COMMONFLAGS} || exit 8
echo "---> STAGE 1"
ninja install || exit 16

sleep 3

if [[ ! -d $TOPLEV/stage2-gen ]] ; then
	mkdir $TOPLEV/stage2-gen
fi
cd $TOPLEV/stage2-gen
CPATH=$TOPLEV/stage1/install/bin/
ninja clean
cmake -G Ninja "$TOPLEV/llvm-${PKGVER}.src" -DCMAKE_C_COMPILER=$CPATH/clang \
-DCMAKE_CXX_COMPILER=$CPATH/clang++ -DCMAKE_INSTALL_PREFIX="$TOPLEV/stage2-gen/install" \
-DLLVM_USE_LINKER=lld -DLLVM_BUILD_INSTRUMENTED=ON ${COMMONFLAGS} || exit 8
echo "---> STAGE 2 GENERATION"
ninja install || exit 16

sleep 3

if [[ ! -d $TOPLEV/stage3-train ]] ; then
	mkdir $TOPLEV/stage3-train
fi
cd $TOPLEV/stage3-train
CPATH=$TOPLEV/stage2-gen/install/bin
ninja clean
cmake -G Ninja "$TOPLEV/llvm-${PKGVER}.src" -DCMAKE_C_COMPILER=$CPATH/clang \
-DCMAKE_CXX_COMPILER=$CPATH/clang++ -DCMAKE_INSTALL_PREFIX="$TOPLEV/stage3-train/install" \
-DLLVM_USE_LINKER=lld ${COMMONFLAGS} || exit 8
echo "---> STAGE 3 TRAIN"
ninja clang || exit 16

sleep 3

cd $TOPLEV/stage2-gen/profiles
$TOPLEV/stage1/install/bin/llvm-profdata merge -output=clang.profdata *

if [[ ! -d $TOPLEV/stage4-final ]] ; then
	mkdir $TOPLEV/stage4-final
fi
cd $TOPLEV/stage4-final
CPATH=$TOPLEV/stage1/install/bin/
ninja clean
cmake -G Ninja "$TOPLEV/llvm-${PKGVER}.src" -DCMAKE_C_COMPILER=$CPATH/clang \
-DCMAKE_CXX_COMPILER=$CPATH/clang++ -DCMAKE_INSTALL_PREFIX="$TOPLEV/stage4-final/install" \
-DLLVM_USE_LINKER=lld -DLLVM_ENABLE_LTO=Full \
-DLLVM_PROFDATA_FILE="${TOPLEV}/stage2-gen/profiles/clang.profdata" ${COMMONFLAGS} || exit 8
echo "---> STAGE 4 FINAL"
ninja check-all || exit 32
ninja install || exit 16

echo "---> DONE!"
echo "---> clang is in $TOPLEV/stage4-final/install/bin"

