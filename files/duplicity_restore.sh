#!/bin/bash

# duply is passing the SIGN_KEY paramter to the restore command
	# this is causing an error 22 and restore is failing
	# 
	# duply data restore /restore || exit 1
	# 
	# workaround using duplicity
PASSPHRASE=${GPG_GEN_PASS} duplicity restore --name duply_data --encrypt-key "$(gpg_setup get-key)" --verbosity '4'  \
	  --gpg-options '--pinentry-mode loopback'  --use-agent --allow-source-mismatch \
	  --exclude-filelist '/root/.duply/data/exclude' "${DUPLY_TARGET}" "${DUPLY_SOURCE}"
