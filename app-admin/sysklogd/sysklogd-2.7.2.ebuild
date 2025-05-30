# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit eapi9-ver flag-o-matic systemd toolchain-funcs

DESCRIPTION="Standard log daemons"
HOMEPAGE="https://troglobit.com/sysklogd.html https://github.com/troglobit/sysklogd"

if [[ ${PV} == *9999 ]] ; then
	inherit autotools git-r3
	EGIT_REPO_URI="https://github.com/troglobit/sysklogd.git"
else
	SRC_URI="https://github.com/troglobit/sysklogd/releases/download/v${PV}/${P}.tar.gz"
	KEYWORDS="~alpha amd64 arm arm64 ~hppa ~mips ppc ppc64 ~riscv ~s390 ~sparc x86"
fi

LICENSE="BSD"
SLOT="0"
IUSE="logger logrotate"
# Needs network access
RESTRICT="test"

DEPEND="
	logger? ( sys-apps/util-linux[-logger(+)] )
"
RDEPEND="
	${DEPEND}
	logrotate? ( app-admin/logrotate )
	!net-misc/inetutils[syslogd]
"

DOCS=( ChangeLog.md README.md )

src_prepare() {
	default

	[[ ${PV} == *9999 ]] && eautoreconf
}

src_configure() {
	append-lfs-flags
	tc-export CC

	local myeconfargs=(
		--disable-static
		--runstatedir="${EPREFIX}"/run
		--with-systemd=$(systemd_get_systemunitdir)
		$(use_with logger)
	)

	econf "${myeconfargs[@]}"
}

src_install() {
	default

	insinto /etc
	doins syslog.conf
	keepdir /etc/syslog.d

	newinitd "${FILESDIR}"/sysklogd.rc10 sysklogd
	newconfd "${FILESDIR}"/sysklogd.confd3 sysklogd

	if use logrotate ; then
		insinto /etc/logrotate.d
		newins "${FILESDIR}"/sysklogd.logrotate sysklogd
		sed 's@ -r 10M:10@@' -i "${ED}"/etc/conf.d/sysklogd || die
	fi

	find "${ED}" -type f -name "*.la" -delete || die
}

pkg_postinst() {
	if ! use logrotate && ver_replacing -lt 2.0 ; then
		elog "Starting with version 2.0 syslogd has built in log rotation"
		elog "functionality that does no longer require a running cron daemon."
		elog "So we no longer install any log rotation cron files for sysklogd."
	fi

	if ver_replacing -lt 2.1 ; then
		elog "Starting with version 2.1 sysklogd no longer provides klogd."
		elog "syslogd now also logs kernel messages."
	fi
}
