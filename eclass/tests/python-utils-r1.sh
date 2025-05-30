#!/bin/bash
# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
source tests-common.sh || exit

eqawarn() {
	: # stub
}

test_var() {
	local var=${1}
	local impl=${2}
	local expect=${3}

	tbegin "${var} for ${impl}"

	local ${var}
	_python_export ${impl} PYTHON ${var}
	[[ ${!var} == ${expect} ]] || eerror "(${impl}: ${var}: ${!var} != ${expect}"

	tend ${?}
}

test_is() {
	local func=${1}
	local expect=${2}

	tbegin "${func} (expecting: ${expect})"

	${func}
	[[ ${?} == ${expect} ]]

	tend ${?}
}

test_fix_shebang() {
	local from=${1}
	local to=${2}
	local expect=${3}
	local args=( "${@:4}" )

	tbegin "python_fix_shebang${args[@]+ ${args[*]}} from ${from@Q} to ${to@Q} (exp: ${expect@Q})"

	echo "${from}" > "${tmpfile}"
	output=$( EPYTHON=${to} python_fix_shebang "${args[@]}" -q "${tmpfile}" 2>&1 )

	if [[ ${?} != 0 ]]; then
		if [[ ${expect} != FAIL ]]; then
			echo "${output}"
			tend 1
		else
			tend 0
		fi
	else
		[[ $(<"${tmpfile}") == ${expect} ]] \
			|| eerror "${from} -> ${to}: $(<"${tmpfile}") != ${expect}"
		tend ${?}
	fi
}

tmpfile=$(mktemp)

inherit multilib python-utils-r1

for minor in {11..14} {13..14}t; do
	ebegin "Testing python3.${minor}"
	eindent
	test_var EPYTHON "python3_${minor}" "python3.${minor}"
	test_var PYTHON "python3_${minor}" "/usr/bin/python3.${minor}"
	if [[ -x /usr/bin/python3.${minor} ]]; then
		abiflags=$(/usr/bin/python3.${minor} -c 'import sysconfig; print(sysconfig.get_config_var("ABIFLAGS"))')
		test_var PYTHON_SITEDIR "python3_${minor}" "/usr/lib*/python3.${minor}/site-packages"
		test_var PYTHON_INCLUDEDIR "python3_${minor}" "/usr/include/python3.${minor%t}${abiflags}"
		test_var PYTHON_LIBPATH "python3_${minor}" "/usr/lib*/libpython3.${minor%t}${abiflags}$(get_libname)"
		test_var PYTHON_CONFIG "python3_${minor}" "/usr/bin/python3.${minor%t}${abiflags}-config"
		test_var PYTHON_CFLAGS "python3_${minor}" "*-I/usr/include/python3.${minor}*"
		test_var PYTHON_LIBS "python3_${minor}" "*-lpython3.${minor}*"
	fi
	test_var PYTHON_PKG_DEP "python3_${minor}" "*dev-lang/python*:3.${minor}"
	PYTHON_REQ_USE=sqlite test_var PYTHON_PKG_DEP "python3_${minor}" "*dev-lang/python*:3.${minor}\[sqlite\]"
	test_var PYTHON_SCRIPTDIR "python3_${minor}" "/usr/lib/python-exec/python3.${minor}"

	tbegin "Testing that python3_${minor} is present in an impl array"
	has "python3_${minor}" "${_PYTHON_ALL_IMPLS[@]}"
	has_in_all=${?}
	has "python3_${minor}" "${_PYTHON_HISTORICAL_IMPLS[@]}"
	has_in_historical=${?}
	if [[ ${has_in_all} -eq ${has_in_historical} ]]; then
		if [[ ${has_in_all} -eq 1 ]]; then
			eerror "python3_${minor} not found in _PYTHON_ALL_IMPLS or _PYTHON_HISTORICAL_IMPLS"
		else
			eerror "python3_${minor} listed both in _PYTHON_ALL_IMPLS and _PYTHON_HISTORICAL_IMPLS"
		fi
	fi
	tend ${?}

	tbegin "Testing that PYTHON_COMPAT accepts the impl"
	(
		# NB: we add pypy3 as we need to always have at least one
		# non-historical impl
		PYTHON_COMPAT=( pypy3 "python3_${minor}" )
		_python_set_impls
	)
	tend ${?}

	# these tests apply to py3.8+ only
	if [[ ${minor%t} -ge 8 ]]; then
		tbegin "Testing that _python_verify_patterns accepts stdlib version"
		( _python_verify_patterns "3.${minor%t}" )
		tend ${?}

		tbegin "Testing _python_impl_matches on stdlib version"
		_python_impl_matches "python3_${minor}" "3.${minor%t}"
		tend ${?}
	fi

	eoutdent
done

for minor in 11; do
	ebegin "Testing pypy3.${minor}"
	eindent
	test_var EPYTHON "pypy3.${minor}" "pypy3.${minor}"
	test_var PYTHON "pypy3.${minor}" "/usr/bin/pypy3.${minor}"
	if [[ -x /usr/bin/pypy3.${minor} ]]; then
		test_var PYTHON_SITEDIR "pypy3.${minor}" "/usr/lib*/pypy3.${minor}/site-packages"
		test_var PYTHON_INCLUDEDIR "pypy3.${minor}" "/usr/include/pypy3.${minor}"
	fi
	test_var PYTHON_PKG_DEP "pypy3.${minor}" '*dev-lang/pypy*:3.11='
	PYTHON_REQ_USE=sqlite test_var PYTHON_PKG_DEP "pypy3.${minor}" '*dev-lang/pypy*:3.11=\[sqlite\]'
	test_var PYTHON_SCRIPTDIR "pypy3.${minor}" "/usr/lib/python-exec/pypy3.${minor}"
	eoutdent
done

for EPREFIX in '' /foo; do
	einfo "Testing python_fix_shebang with EPREFIX=${EPREFIX@Q}"
	eindent
	# generic shebangs
	test_fix_shebang '#!/usr/bin/python' python3.6 \
		"#!${EPREFIX}/usr/bin/python3.6"
	test_fix_shebang '#!/usr/bin/python' pypy3 \
		"#!${EPREFIX}/usr/bin/pypy3"

	# python2/python3 matching
	test_fix_shebang '#!/usr/bin/python3' python3.6 \
		"#!${EPREFIX}/usr/bin/python3.6"
	test_fix_shebang '#!/usr/bin/python2' python3.6 FAIL
	test_fix_shebang '#!/usr/bin/python2' python3.6 \
		"#!${EPREFIX}/usr/bin/python3.6" --force

	# pythonX.Y matching (those mostly test the patterns)
	test_fix_shebang '#!/usr/bin/python2.7' python3.2 FAIL
	test_fix_shebang '#!/usr/bin/python2.7' python3.2 \
		"#!${EPREFIX}/usr/bin/python3.2" --force
	test_fix_shebang '#!/usr/bin/python3.2' python3.2 \
		"#!${EPREFIX}/usr/bin/python3.2"

	# fancy path handling
	test_fix_shebang '#!/mnt/python2/usr/bin/python' python3.6 \
		"#!${EPREFIX}/usr/bin/python3.6"
	test_fix_shebang '#!/mnt/python2/usr/bin/python3' python3.8 \
		"#!${EPREFIX}/usr/bin/python3.8"
	test_fix_shebang '#!/mnt/python2/usr/bin/env python' python3.8 \
		"#!${EPREFIX}/usr/bin/python3.8"
	test_fix_shebang '#!/mnt/python2/usr/bin/python3 python3' python3.8 \
		"#!${EPREFIX}/usr/bin/python3.8 python3"
	test_fix_shebang '#!/mnt/python2/usr/bin/python2 python3' python3.8 FAIL
	test_fix_shebang '#!/mnt/python2/usr/bin/python2 python3' python3.8 \
		"#!${EPREFIX}/usr/bin/python3.8 python3" --force
	test_fix_shebang '#!/usr/bin/foo' python3.8 FAIL

	# regression test for bug #522080
	test_fix_shebang '#!/usr/bin/python ' python3.8 \
		"#!${EPREFIX}/usr/bin/python3.8 "

	# test random whitespace in shebang
	test_fix_shebang '#! /usr/bin/python' python3.8 \
		"#!${EPREFIX}/usr/bin/python3.8"
	test_fix_shebang '#!  /usr/bin/python' python3.8 \
		"#!${EPREFIX}/usr/bin/python3.8"
	test_fix_shebang '#! /usr/bin/env   python' python3.8 \
		"#!${EPREFIX}/usr/bin/python3.8"

	# test preserving options
	test_fix_shebang '#! /usr/bin/python -b' python3.8 \
		"#!${EPREFIX}/usr/bin/python3.8 -b"
	eoutdent
done

# check _python_impl_matches behavior
einfo "Testing python_impl_matches"
eindent
test_is "_python_impl_matches python3_6 -3" 0
test_is "_python_impl_matches python3_7 -3" 0
test_is "_python_impl_matches pypy3 -3" 0
set -f
test_is "_python_impl_matches python3_6 pypy*" 1
test_is "_python_impl_matches python3_7 pypy*" 1
test_is "_python_impl_matches pypy3 pypy*" 0
test_is "_python_impl_matches python3_6 python*" 0
test_is "_python_impl_matches python3_7 python*" 0
test_is "_python_impl_matches pypy3 python*" 1
set +f
test_is "_python_impl_matches python3_11 3.10" 1
test_is "_python_impl_matches python3_11 3.11" 0
test_is "_python_impl_matches python3_11 3.12" 1
test_is "_python_impl_matches python3_12 3.10" 1
test_is "_python_impl_matches python3_12 3.11" 1
test_is "_python_impl_matches python3_12 3.12" 0
test_is "_python_impl_matches python3_13 3.13" 0
test_is "_python_impl_matches python3_13t 3.13" 0
test_is "_python_impl_matches python3_13 3.14" 1
test_is "_python_impl_matches python3_13t 3.14" 1
test_is "_python_impl_matches python3_14 3.13" 1
test_is "_python_impl_matches python3_14t 3.13" 1
test_is "_python_impl_matches python3_14 3.14" 0
test_is "_python_impl_matches python3_14t 3.14" 0
test_is "_python_impl_matches pypy3_11 3.10" 1
test_is "_python_impl_matches pypy3_11 3.11" 0
test_is "_python_impl_matches pypy3_11 3.12" 1
# https://bugs.gentoo.org/955213
test_is "_python_impl_matches python3_11 3.10 3.11" 0
test_is "_python_impl_matches python3_11 3.11 3.12" 0
test_is "_python_impl_matches python3_11 3.10 3.12" 1
test_is "_python_impl_matches python3_11 3.10 3.11 3.12" 0
test_is "_python_impl_matches python3_12 3.10 3.11" 1
test_is "_python_impl_matches python3_12 3.11 3.12" 0
test_is "_python_impl_matches python3_12 3.10 3.12" 0
test_is "_python_impl_matches python3_12 3.10 3.11 3.12" 0
test_is "_python_impl_matches python3_11 python3_10 python3_11" 0
test_is "_python_impl_matches python3_11 python3_11 python3_12" 0
test_is "_python_impl_matches python3_11 python3_10 python3_12" 1
test_is "_python_impl_matches python3_11 python3_10 python3_11 python3_12" 0
test_is "_python_impl_matches python3_12 python3_10 python3_11" 1
test_is "_python_impl_matches python3_12 python3_11 python3_12" 0
test_is "_python_impl_matches python3_12 python3_10 python3_12" 0
test_is "_python_impl_matches python3_12 python3_10 python3_11 python3_12" 0
eoutdent

rm "${tmpfile}"

texit
