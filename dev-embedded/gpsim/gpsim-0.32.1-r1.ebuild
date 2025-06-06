# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools

DESCRIPTION="A simulator for the Microchip PIC microcontrollers"
HOMEPAGE="https://gpsim.sourceforge.net"
SRC_URI="https://downloads.sourceforge.net/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~arm64 ~ppc ~ppc64 x86"

IUSE="doc gui"

RDEPEND="
	gui? ( x11-libs/gtk+:2 )
	>=dev-embedded/gputils-0.12
	dev-libs/glib:2
	dev-libs/popt
	sys-libs/readline:0=
"
DEPEND="${RDEPEND}"
BDEPEND="
	app-alternatives/lex
	virtual/pkgconfig
	app-alternatives/yacc
"
DOCS=( ANNOUNCE AUTHORS ChangeLog HISTORY PROCESSORS README README.MODULES \
	TODO doc/gpsim.pdf )
HTML_DOCS=( doc/gpsim.html.LyXconv/gpsim.html )

PATCHES=(
	"${FILESDIR}"/${P}-missing-lib-m.patch
	"${FILESDIR}"/${P}-configure.patch
)

src_prepare() {
	default
	eautoreconf
}

src_configure() {
	local myeconfargs=(
		$(usex gui "" --disable-gui)
		--disable-static
	)
	econf "${myeconfargs[@]}"
}

src_install() {
	default
	find "${ED}" -name '*.la' -delete || die
}
