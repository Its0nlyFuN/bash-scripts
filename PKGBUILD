# Maintainer: torvic9

pkgname='mini-benchmarker'
pkgver=0.5.r0.ga2898e9
pkgrel=1
pkgdesc='A simple benchmarking script using sysbench, perf etc.'
url="https://github.com/torvic9/bash-scripts"
arch=('x86_64')
licence=('GPL3')
depends=('make' 'time' 'sysbench' 'perf' 'unzip' 'darktable' 'nasm' 'inxi')
source=(git+https://github.com/torvic9/bash-scripts.git)
sha512sums=('SKIP')

pkgver() {
	cd bash-scripts
	git describe --long | sed 's/^v//;s/\([^-]*-g\)/r\1/;s/-/./g'
}

package() {
	cd bash-scripts
	install -Dm755 benchmarker.sh "$pkgdir/usr/bin/$pkgname.sh"
}
