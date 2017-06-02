#!/bin/bash

_profile_root="/root/.duply/data"
_profile_conf="${_profile_root}/conf"
_profile_exclude="${_profile_root}/exclude"
_env_prefix="DUPLY_"


if [ -d /tmp/docker-backup/duply-conf ]; then
    cp -rv /tmp/docker-backup/duply-conf/ "${_profile_root}"
elif [ ! -d "${_profile_root}" ]; then
    mkdir -p "${_profile_root}"

    cat > "${_profile_conf}" <<EOF
# GPG
GPG_KEY=
GPG_KEY_SIGN=
GPG_PW=

# Base directory to backup
SOURCE='/'
TARGET="file://tmp"

VOLSIZE=100
DUPL_PARAMS="\$DUPL_PARAMS --volsize \$VOLSIZE "

# Backup retention
MAX_AGE=2M
MAX_FULL_BACKUPS=2
MAX_FULLS_WITH_INCRS=1
MAX_FULLBKP_AGE=1M
DUPL_PARAMS="\$DUPL_PARAMS --full-if-older-than \$MAX_FULLBKP_AGE "
DUPL_PARAMS="\$DUPL_PARAMS --use-agent --allow-source-mismatch "
EOF

    IFS=";"
    for item in $DUPLY_INCLIST;do
	echo "+ $item" >> "${_profile_exclude}" 
    done

    for item in $DUPLY_EXCLIST;do
	echo "- $item" >> "${_profile_exclude}" 
    done

    [[ $DUPY_ENCRYPTION != 'yes' ]] && \
	sed -i -e "/GPG.*/ s|^#*|#|" /root/.duply/data/conf 

    override_config "${_env_prefix}" "${_profile_conf}"
fi
