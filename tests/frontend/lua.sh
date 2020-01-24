#! /usr/bin/env atf-sh

. $(atf_get_srcdir)/test_environment.sh

tests_init \
	script_basic \
	script_message \
	script_rooteddir

script_basic_body() {
	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_pkg "test" "test" "1"
	cat << EOF >> test.ucl
lua_scripts: {
  post-install: [
  'print("this is post install1")',
  'print("this is post install2")',
  ]
}
EOF

	atf_check \
		-o empty \
		-e empty \
		-s exit:0 \
		pkg create -M test.ucl

	mkdir ${TMPDIR}/target
	atf_check \
		-o inline:"this is post install1\nthis is post install2\n" \
		-e empty \
		-s exit:0 \
		pkg -o REPOS_DIR=/dev/null -r ${TMPDIR}/target install -qfy ${TMPDIR}/test-1.txz

}

script_message_body() {
	# The message should be the last thing planned
	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_pkg "test" "test" "1"
	cat << EOF >> test.ucl
lua_scripts: {
  post-install: [
  "print(\"this is post install1\")\npkg.print_msg(\"this is a message\")",
  'print("this is post install2")',
  ]
}
EOF

	atf_check \
		-o empty \
		-e empty \
		-s exit:0 \
		pkg create -M test.ucl

	mkdir ${TMPDIR}/target
	atf_check \
		-o inline:"this is post install1\nthis is post install2\nthis is a message\n" \
		-e empty \
		-s exit:0 \
		pkg -o REPOS_DIR=/dev/null -r ${TMPDIR}/target install -qfy ${TMPDIR}/test-1.txz

}

script_rooteddir_body() {
	# The message should be the last thing planned
	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_pkg "test" "test" "1"
	cat << EOF >> test.ucl
lua_scripts: {
  post-install: [ <<EOS
test = io.open("/file.txt", "w+")
test:write("test\n")
io.close(test)
EOS
,
  ]
}
EOF

	atf_check \
		-o empty \
		-e empty \
		-s exit:0 \
		pkg create -M test.ucl

	mkdir ${TMPDIR}/target
	atf_check \
		-e empty \
		-s exit:0 \
		pkg -o REPOS_DIR=/dev/null -r ${TMPDIR}/target install -qfy ${TMPDIR}/test-1.txz
	[ -f ${TMPDIR}/target/file.txt ] || atf_fail "File not created in the rootdir"
	# test the mode
	atf_check -o match:"^-rw-r--r--" ls -l ${TMPDIR}/target/file.txt
	atf_check \
		-e empty \
		-o inline:"test\n" \
		-s exit:0 \
		cat ${TMPDIR}/target/file.txt

}