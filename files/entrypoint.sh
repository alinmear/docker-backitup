#!/bin/bash
declare -A DEFAULT_VARS

default_vars() {
  DEFAULT_VARS['GPG_GEN_KEY_TYPE']="${GPG_GEN_KEY_TYPE:="RSA"}"
  DEFAULT_VARS['GPG_GEN_KEY_LENGTH']="${GPG_GEN_KEY_LENGTH:="2048"}"
  DEFAULT_VARS['GPG_GEN_SUBKEY_TYPE']="${GPG_GEN_SUBKEY_TYPE:="RSA"}"
  DEFAULT_VARS['GPG_GEN_SUBKEY_LENGTH']="${GPG_GEN_SUBKEY_LENGTH:="2048"}"
  DEFAULT_VARS['GPG_GEN_NAME']="${GPG_GEN_NAME:="'Duplicity Backup'"}"
  DEFAULT_VARS['GPG_GEN_EMAIL']="${GPG_GEN_EMAIL:="backup@localhost"}"

  [ -f /gpg_home/gpg_info ] && [ -z "${GPG_GEN_PASS}" ] && \
  export GPG_GEN_PASS="$(cat /gpg_home/gpg_info)"

  DEFAULT_VARS['GPG_GEN_PASS']="${GPG_GEN_PASS:="$(pwgen 16 1)"}"

  DEFAULT_VARS['GPG_GEN_BATCH_FILE']="${GPG_GEN_BATCH_FILE:="/tmp/docker-backup/gpg_batch"}"

  DEFAULT_VARS['MYSQL_HOST']="${MYSQL_HOST:="mysql"}"
  DEFAULT_VARS['MYSQL_PORT']="${MYSQL_PORT:="3306"}"
  DEFAULT_VARS['MYSQL_USER']="${MYSQL_USER:="root"}"
  DEFAULT_VARS['MYSQL_PASS']="${MYSQL_PASS:="root"}"
  DEFAULT_VARS['MYSQL_DBS']="${MYSQL_DBS:="--all-databases"}"
  DEFAULT_VARS['MYSQL_MAX_BACKUPS']="${MYSQL_MAX_BACKUPS:="20"}"
  DEFAULT_VARS['MYSQL_PARAMS']="${MYSQL_PARAMS:=""}"

  DEFAULT_VARS['DUPLY_SOURCE']="${DUPLY_SOURCE:="/backup_source/"}"
  DEFAULT_VARS['DUPLY_TARGET']="${DUPLY_TARGET:="'file:///backup/data/'"}"
  DEFAULT_VARS['DUPLY_INCLIST']="${DUPLY_INCLIST:=""}"
  DEFAULT_VARS['DUPLY_EXCLIST']="${DUPLY_EXCLIST:=""}"
  DEFAULT_VARS['DUPLY_ENCRYPTION']="${DUPLY_ENCRYPTION:="yes"}"

  [ -f /gpg_home/gpg_info ] && [ -z "${DUPLY_GPG_PW}" ] && \
  export DUPLY_GPG_PW="$(cat /gpg_home/gpg_info)"

  DEFAULT_VARS['DUPLY_GPG_PW']="${DUPLY_GPG_PW:="${GPG_GEN_PASS}"}"
  DEFAULT_VARS['DUPLY_VOLSIZE']="${DUPLY_VOLSIZE:="100"}"
  DEFAULT_VARS['DUPLY_MAX_AGE']="${DUPLY_MAX_AGE:="2M"}"
  DEFAULT_VARS['DUPLY_MAX_FULL_BACKUPS']="${DUPLY_MAX_FULL_BACKUPS:="2"}"
  DEFAULT_VARS['DUPLY_MAX_FULLS_WITH_INCRS']="${DUPLY_MAX_FULLS_WITH_INCRS:="1"}"
  DEFAULT_VARS['DUPLY_MAX_FULLBKP_AGE']="${DUPLY_MAX_FULLBKP_AGE:="1M"}"

  DEFAULT_VARS['DUPLY_CRON_ENABLED']="${DUPLY_CRON_ENABLED:="yes"}"
  DEFAULT_VARS['MYSQL_CRON_ENABLED']="${MYSQL_CRON_ENABLED:="yes"}"

  DEFAULT_VARS['DUPLY_CRON']="${DUPLY_CRON:="'* 0 * * *'"}"
  DEFAULT_VARS['MYSQL_CRON']="${MYSQL_CRON:="'* 0 * * *'"}"

  # need this to get gpg working within docker, alpine and duply
    cat > /root/.bashrc <<EOF
# ADDED by docker-backup
# export GPG_TTY=/dev/console
export GPG_OPTS='--pinentry-mode loopback'
EOF

  for var in ${!DEFAULT_VARS[@]}; do
    # export "$var=${DEFAULT_VARS[$var]}"
	cat >> /root/.bashrc <<EOF
# ADDED by docker-backup
export "$var=${DEFAULT_VARS[$var]}"
EOF
  done
  source /root/.bashrc
}

copy_custom_configs() {
  local _folder="/tmp/docker-backitup"
  [ ! -d "$_folder" ] && return 1

  # copy gpg_home if exists
  _folder_gpg_home="${_folder}/gpg_home"
  [ -d "$_folder_gpg_home" ] && \
  cp -r "${_folder_gpg_home}/*" /gpg_home
}

# first copy custom configs then init the default vars
# care, we must copy custom configs first because some default vars getting
# initalized by files within the gpg_home
copy_custom_configs
default_vars

case "$1" in
  'bash')
    exec bash
  ;;
  'export')
    backitup_export
  ;;
  *)
    # setup config and gpg for duplicity-backup.sh
    duply_setup
    [[ $DUPLY_ENCRYPTION == yes ]] && gpg_setup
    cron_setup

    # startup supervisord from Docker cmd
    "$@"
  ;;
esac

exit 0
