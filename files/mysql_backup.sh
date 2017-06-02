#!/bin/bash
_max_backups="${MYSQL_MAX_BACKUPS}"
_host="${MYSQL_HOST}"
_port="${MYSQL_PORT}"
_user="${MYSQL_USER}"
_pass="${MYSQL_PASS}"
_dbs="${MYSQL_DBS}"
_params="${MYSQL_PARAMS}"

__backup_folder="/backup/dbs"

check_connection() {
    bash -c "cat < /dev/null > /dev/tcp/${_host}/${_port}" >/dev/null 2>/dev/null
    return $?
}

success () {
    echo -e "\n\n==> Mysql Backup:\n  \e[0;32m*\e[0m Backup for $1 has been successfully executed\n\n"
}

failed() {
    echo -e "\n\n==> Mysql Backup:\n  \e[0;31m*\e[0m Backup for ${1} failed\n\n"
    rm -rf "${__backup_folder}/${2}"
}

backup() {
    if [[ "${_dbs}" == "--all-databases" ]]
    then
	local _name="$(date +%Y-%m-%d_%H-%M-%S)_all-dbs.sql"

	echo -e "\n\n==> Mysql Backup:\n  Starting Backup ${_name}\n\n"
	backup_dump "${_dbs}" "${_name}" && success "${_dbs}" || failed "${_dbs}" "${_name}"
    else
	for db in ${_dbs}; do
	    local _name="$(date +%Y-%m-%d_%H-%M-%S)_${db}.sql"

	    echo -e "\n\n==> Mysql Backup:\n  Starting Backup ${_name}\n\n"
	    backup_dump "${db}" "${_name}" && success "${db}" || failed "${db}" "${_name}"
	done
    fi
}

backup_dump() {
    # remove quotes from $_params
    _params=$(sed -e 's/^"//' -e 's/"$//' -e "s/^\'//" -e "s/\'$//" <<<"$_params")
    mysqldump -h${_host} -P${_port} -u${_user} -p${_pass} ${_params} "${1}" > "${__backup_folder}/${2}"
    return $?
}

restore () {
    # TODO
    echo "Not implemented"
}

cleanup() {
    if [ -n "${_max_backups}" ]; then
	while [[ $(ls ${__backup_folder} -1 | wc -l) -gt "${_max_backups}" ]]
	do
	    local _file_delete="$(ls ${__backup_folder} -1 | sort | head -n 1)"
	    rm -f "${__backup_folder}/${_file_delete}" && \
		echo -e "\n\n==> Mysql Backup:\n  \e[0;32m*\e[0m old backup ${_file_delete} deleted \n\n" || \
		    echo -e "\n\n==> Mysql Backup:\n  \e[0;31m*\e[0m old backup ${_file_delete} deletion failed \n\n"
	done
    fi
}

[ ! -d "${__backup_folder}" ] && mkdir -p "${__backup_folder}" 

check_connection
if [[ $? == 0 ]]; then
    case "$1" in
	"backup")
	    backup
	    cleanup
	    ;;
	"restore")
	    restore
	    ;;
    esac
else
    echo "Can't connect to ${_host}. Exiting ..."
    exit 1
fi

exit 0
