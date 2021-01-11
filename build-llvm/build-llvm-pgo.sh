#!/bin/bash

# basic script to build pgo clang
# needs manual adjustments
# single argument is a full path to store all build files
# torvic9

[[ -z $1 ]] && echo "specify full path for build files!" && exit 4
TOPLEV=$1
PKGVER="11.0.1-rc2"
NCORES=`nproc`
export CFLAGS="-O2 -march=native -pipe"
export CXXFLAGS="-O2 -march=native -pipe"
export LDFLAGS="-Wl,-O1,-z,relro,-z,now"
COMMONFLAGS="-DLLVM_HOST_TRIPLE=x86_64-pc-linux-gnu \
 -DLLVM_ENABLE_PROJECTS='clang;lld;compiler-rt' \
 -DLLVM_TARGETS_TO_BUILD=X86 \
 -DLLVM_ENABLE_RTTI=OFF \
 -DLLVM_ENABLE_WARNINGS=OFF \
 -DLLVM_ENABLE_SPHINX=OFF \
 -DLLVM_ENABLE_DOXYGEN=OFF \
 -DCMAKE_BUILD_TYPE=Release \
 -DLLVM_BINUTILS_INCDIR=/usr/include \
 -DLLVM_PARALLEL_COMPILE_JOBS=24 \
 -DLLVM_PARALLEL_LINK_JOBS=12 \
 -DLLVM_ENABLE_BINDINGS=OFF \
 -DLLVM_ENABLE_OCAMLDOC=OFF \
 -DLLVM_ENABLE_PLUGINS=ON \
 -DLLVM_ENABLE_TERMINFO=OFF \
 -DLLVM_INCLUDE_DOCS=OFF \
 -DLLVM_INCLUDE_EXAMPLES=OFF \
 -DLLVM_LINK_LLVM_DYLIB=ON \
 -DCLANG_LINK_CLANG_DYLIB=ON \
 -DCLANG_PLUGIN_SUPPORT=ON \
 -DCLANG_ENABLE_ARCMT=OFF \
 -DCLANG_ENABLE_STATIC_ANALYZER=OFF \
 -DCOMPILER_RT_BUILD_LIBFUZZER=OFF"

[[ ! -d $TOPLEV ]] && mkdir $TOPLEV

cd $TOPLEV

if [[ ! -d llvm-project-${PKGVER/-/} ]] ; then
	wget -O llvm-${PKGVER}.tar.xz --show-progress https://github.com/llvm/llvm-project/releases/download/llvmorg-${PKGVER}/llvm-project-${PKGVER/-/}.src.tar.xz
	tar xf llvm-${PKGVER}.tar.xz
fi

#[[ ! -d $TOPLEV ]] && mkdir $TOPLEV
#cd $TOPLEV
#if [[ -d llvm-project ]] ; then
#	cd llvm-project && git pull
#else
#	git clone https://github.com/llvm/llvm-project.git -b release/11.x --single-branch
#fi

if [[ ! -d $TOPLEV/stage1 ]] ; then
	mkdir $TOPLEV/stage1
fi

cd $TOPLEV/stage1

ninja clean
cmake -G Ninja "$TOPLEV/llvm-project-${PKGVER/-/}.src/llvm" -DCMAKE_C_COMPILER=/usr/bin/gcc \
-DCMAKE_CXX_COMPILER=/usr/bin/g++ -DLLVM_INCLUDE_TESTS=OFF \
-DCMAKE_INSTALL_PREFIX="$TOPLEV/stage1/install" -DLLVM_CCACHE_BUILD=ON \
-DCOMPILER_RT_BUILD_SANITIZERS=OFF -DLLVM_ENABLE_BACKTRACES=OFF \
-DLLVM_INCLUDE_UTILS=OFF ${COMMONFLAGS} || exit 8

echo "----> STAGE 1"
ninja install || exit 16

sleep 2

if [[ ! -d $TOPLEV/stage2-gen ]] ; then
	mkdir $TOPLEV/stage2-gen
fi

cd $TOPLEV/stage2-gen

CPATH=$TOPLEV/stage1/install/bin/
ninja clean
cmake -G Ninja "$TOPLEV/llvm-project-${PKGVER/-/}.src/llvm" -DCMAKE_C_COMPILER=$CPATH/clang \
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
cmake -G Ninja "$TOPLEV/llvm-project-${PKGVER/-/}.src/llvm" -DCMAKE_C_COMPILER=$CPATH/clang \
-DCMAKE_CXX_COMPILER=$CPATH/clang++ -DCMAKE_INSTALL_PREFIX="$TOPLEV/stage3-train/install" \
-DLLVM_USE_LINKER=lld ${COMMONFLAGS} || exit 8

echo "----> STAGE 3 TRAIN"
ninja clang || exit 16

sleep 2

echo "----> PROFILE MERGE"

cd $TOPLEV/stage2-gen/profiles
$TOPLEV/stage1/install/bin/llvm-profdata merge -output=clang.profdata *

if [[ ! -d $TOPLEV/stage4-final ]] ; then
	mkdir $TOPLEV/stage4-final
fi

cd $TOPLEV/stage4-final

CPATH=$TOPLEV/stage1/install/bin/
ninja clean
cmake -G Ninja "$TOPLEV/llvm-project-${PKGVER/-/}.src/llvm" -DCMAKE_C_COMPILER=$CPATH/clang \
-DCMAKE_CXX_COMPILER=$CPATH/clang++ -DCMAKE_INSTALL_PREFIX="$TOPLEV/stage4-final/Release" \
-DLLVM_USE_LINKER=lld -DLLVM_ENABLE_LTO=Thin \
-DLLVM_PROFDATA_FILE="${TOPLEV}/stage2-gen/profiles/clang.profdata" ${COMMONFLAGS} || exit 8

echo "---> STAGE 4 FINAL"
ninja check-lld || exit 32 ; ninja check-clang || exit 32
ninja install || exit 16

echo "----> DONE!"
echo "----> clang is in $TOPLEV/stage4-final/Release"

