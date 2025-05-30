# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
ADA_COMPAT=( gcc_{12..15} )
inherit ada

MYP=${P}-${PV}0518-19D3B-src
ID=884f3b229457c995ddebb46a16a7cc50ed837c90
ADAMIRROR=https://community.download.adacore.com/v1

DESCRIPTION="Translates addresses into filename, line number, and function names"
HOMEPAGE="http://libre.adacore.com/"
SRC_URI="${ADAMIRROR}/${ID}?filename=${MYP}.tar.gz -> ${MYP}.tar.gz"

S="${WORKDIR}"/${MYP}

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64 ~arm64 x86"

RDEPEND="${ADA_DEPS}"
DEPEND="${RDEPEND}"
REQUIRED_USE="${ADA_REQUIRED_USE}"

src_compile() {
	gnatmake -v gnatsymbolize -cargs ${ADAFLAGS} -largs ${LDFLAGS} || die
}

src_install() {
	dobin gnatsymbolize
}
