# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=poetry
PYTHON_COMPAT=( python3_{11..14} pypy3_11 )

inherit distutils-r1 pypi

DESCRIPTION="Testing library to create mocks, stubs and fakes"
HOMEPAGE="
	https://flexmock.readthedocs.io/
	https://github.com/flexmock/flexmock/
	https://pypi.org/project/flexmock/
"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 ~arm arm64 ~riscv x86"

distutils_enable_tests pytest

python_test() {
	local EPYTEST_IGNORE=(
		tests/test_teamcity.py
		tests/test_testtools.py
		tests/test_unittest.py
	)
	epytest -p no:flaky
}

python_install_all() {
	distutils-r1_python_install_all
	dodoc -r docs
}
