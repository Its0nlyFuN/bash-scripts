#!/bin/bash

# basic script to build pgo clang
# needs manual adjustments
# single argument is a full path to store all build files
# torvic9

[[ -z $1 ]] && echo "specify full path for build files!" && exit 4
TOPLEV=$1
PKGVER="10.0.1rc1"
NCORES=`nproc`
export CFLAGS="-O3 -march=native -pipe"
export CXXFLAGS="-O3 -march=native -pipe"
#export LDFLAGS="-Wl,-O1"
COMMONFLAGS="-DLLVM_ENABLE_PROJECTS=clang;clang-tools-extra;compiler-rt;lld \
-DLLVM_LINK_LLVM_DYLIB=ON \
-DLLVM_TARGETS_TO_BUILD=X86;AMDGPU
-DLLVM_HOST_TRIPLE=x86_64-pc-linux-gnu \
-DLLVM_ENABLE_RTTI=ON \
-DLLVM_ENABLE_WARNINGS=OFF \
-DLLVM_ENABLE_SPHINX=OFF \
-DLLVM_ENABLE_DOXYGEN=OFF \
-DCMAKE_BUILD_TYPE=Release \
-DLLVM_BINUTILS_INCDIR=/usr/include \
-DLLVM_PARALLEL_COMPILE_JOBS=${NCORES} -DLLVM_PARALLEL_LINK_JOBS=${NCORES} \
-DLLVM_ENABLE_BINDINGS=OFF \
-DLLVM_ENABLE_OCAMLDOC=OFF \
-DLLVM_ENABLE_PLUGINS=ON \
-DLLVM_ENABLE_TERMINFO=OFF \
-DLLVM_INCLUDE_DOCS=OFF \
-DLLVM_INCLUDE_EXAMPLES=OFF \
-DCOMPILER_RT_BUILD_LIBFUZZER=OFF \
-DCLANG_LINK_CLANG_DYLIB=ON \
-DCLANG_PLUGIN_SUPPORT=OFF \
-DCLANG_ENABLE_ARCMT=OFF \
-DCLANG_ENABLE_STATIC_ANALYZER=OFF"

#-DLIBCXX_INCLUDE_TESTS=OFF \
#-DLIBCXX_CXX_ABI_INCLUDE_PATHS=/usr/include/c++/v1 \
#-DLIBCXX_CXX_ABI_LIBRARY_PATH=/usr/lib \
#-DLIBCXX_CXX_ABI=libcxxabi \
#-DLIBCXX_ENABLE_SHARED=ON \
#-DLIBCXX_INCLUDE_TESTS=OFF \
#-DLIBCXX_INCLUDE_BENCHMARKS=OFF"
#-DLIBCXXABI_LIBCXX_PATH=/usr/lib \
#-DLIBCXXABI_LIBCXX_INCLUDES=/usr/include \
#-DLIBCXX_INSTALL_PREFIX="$TOPLEV/stage1/install" (add this to each stage)

[[ ! -d $TOPLEV ]] && mkdir $TOPLEV
cd $TOPLEV
if [[ ! -d llvm-${PKGVER}.src ]] ; then
	wget -nc -qO llvm-${PKGVER}.tar.xz --show-progress https://github.com/llvm/llvm-project/releases/download/llvmorg-10.0.1-rc1/llvm-project-${PKGVER}.tar.xz
	tar xf llvm-${PKGVER}.tar.xz
fi

if [[ ! -d $TOPLEV/stage1 ]] ; then
	mkdir $TOPLEV/stage1
fi
cd $TOPLEV/stage1
if [[ ! -f ./bin/clang-10 ]] ; then
	ninja clean
	cmake -G Ninja "$TOPLEV/llvm-project-${PKGVER}/llvm" -DCMAKE_C_COMPILER=/usr/bin/gcc -DCMAKE_CXX_COMPILER=/usr/bin/g++ \
-DLLVM_CCACHE_BUILD=ON -DCMAKE_INSTALL_PREFIX="$TOPLEV/stage1/install" \
-DCOMPILER_RT_BUILD_SANITIZERS=OFF -DLLVM_ENABLE_BACKTRACES=OFF -DLLVM_INCLUDE_TESTS=OFF \
-DLLVM_INCLUDE_UTILS=OFF ${COMMONFLAGS} || exit 8
	echo "----> STAGE 1"
	ninja install || exit 16
fi

sleep 2

if [[ ! -d $TOPLEV/stage2-gen ]] ; then
	mkdir $TOPLEV/stage2-gen
fi
cd $TOPLEV/stage2-gen
CPATH=$TOPLEV/stage1/install/bin/
ninja clean
cmake -G Ninja "$TOPLEV/llvm-project-${PKGVER}/llvm" -DCMAKE_C_COMPILER=$CPATH/clang \
-DCMAKE_CXX_COMPILER=$CPATH/clang++ -DCMAKE_INSTALL_PREFIX="$TOPLEV/stage2-gen/install" \
-DLLVM_USE_LINKER=lld -DLLVM_BUILD_INSTRUMENTED=IR -DLLVM_BUILD_RUNTIME=OFF ${COMMONFLAGS} || exit 8
echo "----> STAGE 2 GENERATION"
ninja install || exit 16

sleep 2

if [[ ! -d $TOPLEV/stage3-train ]] ; then
	mkdir $TOPLEV/stage3-train
fi
cd $TOPLEV/stage3-train
CPATH=$TOPLEV/stage2-gen/install/bin
ninja clean
cmake -G Ninja "$TOPLEV/llvm-project-${PKGVER}/llvm" -DCMAKE_C_COMPILER=$CPATH/clang \
-DCMAKE_CXX_COMPILER=$CPATH/clang++ -DCMAKE_INSTALL_PREFIX="$TOPLEV/stage3-train/install" \
-DLLVM_USE_LINKER=lld ${COMMONFLAGS} || exit 8
echo "----> STAGE 3 TRAIN"
ninja clang || exit 16

sleep 2

cd $TOPLEV/stage2-gen/profiles
$TOPLEV/stage1/install/bin/llvm-profdata merge -output=clang.profdata *

if [[ ! -d $TOPLEV/stage4-final ]] ; then
	mkdir $TOPLEV/stage4-final
fi
cd $TOPLEV/stage4-final
CPATH=$TOPLEV/stage1/install/bin/
ninja clean
cmake -G Ninja "$TOPLEV/llvm-project-${PKGVER}/llvm" -DCMAKE_C_COMPILER=$CPATH/clang \
-DCMAKE_CXX_COMPILER=$CPATH/clang++ -DCMAKE_INSTALL_PREFIX="$TOPLEV/stage4-final/Release" \
-DLLVM_USE_LINKER=lld -DLLVM_ENABLE_LTO=Full -DLLVM_ENABLE_FFI=ON \
-DLLVM_PROFDATA_FILE="${TOPLEV}/stage2-gen/profiles/clang.profdata" ${COMMONFLAGS} || exit 8
echo "---> STAGE 4 FINAL"
ninja check-lld || exit 32 ; ninja check-clang || exit 32
ninja install || exit 16

echo "----> DONE!"
echo "----> clang is in $TOPLEV/stage4-final/Release"

