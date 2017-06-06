#!/bin/bash

# due a failure with alpine and tty
# taken from http://unix.stackexchange.com/questions/277282/gpg-key-generation-fails-on-alpine-linux-docker-image
export GPG_TTY=/dev/console
_gpg_folder="/gpg_home"
_gpg_export="/backup/gpg_export"
_gpg_info="${_gpg_folder}/gpg_info"
_gpg_agent_conf="${_gpg_folder}/gpg-agent.conf"


gpg_gen() {

    # if key already exists do nothing
    # should be the case if gpg_home is provided
    # at /tmp/docker-backitup/gpg_home
    gpg --list-keys | grep "${GPG_GEN_NAME}" 2>/dev/null 1>/dev/null
    [[ $? == 0 ]] && return 0

    # check for gpg dir
    [ ! -d ${_gpg_export} ] && mkdir -p ${_gpg_export}

    _status=0

    # check first if there are files to import
    [ -f "${_gpg_export}/gpg-key.asc" ] &&  [ -f "${_gpg_export}/gpg-secret-key.asc" ] && \
	_status=1 || _status=3

    # generate new gpg file
    [ -f "${GPG_GEN_BATCH_FILE}" ] && \
	_status=2

    case $_status in
	1)
	    echo "Found gpg keys. Importing ..."
	    gpg_import && return 0 || return 1
	    ;;
	2)
	    echo "Found batch file. Generating ..."
	    gpg_gen_batch_file && return 0 || return 1
	    ;;
	3)
	    echo "Generating new gpg keys ..."
	    gpg_gen_generate && return 0 || return 1
	    ;;
	*)
	    echo "Do not know what to do. Exiting..."
	    exit 1
	    ;;
    esac
}

gpg_gen_batch_file() {
    gpg -gen-key --batch "$1" && return 0 || return 1
}

gpg_gen_generate() {
    echo "Generating gpg key"

    cat << EOF | gpg --batch --gen-key
%echo Generating a new GPG-KEY
Key-Type: $GPG_GEN_KEY_TYPE
Key-Length: $GPG_GEN_KEY_LENGTH
Subkey-Type: $GPG_GEN_SUBKEY_TYPE
Subkey-Length: $GPG_GEN_SUBKEY_LENGTH
Name-Real: $GPG_GEN_NAME
Name-Email: $GPG_GEN_EMAIL
Expire-Date: 0
Passphrase: $GPG_GEN_PASS
%commit
%echo Created key with passphrase '$GPG_GEN_PASS'
EOF

    echo "${GPG_GEN_PASS}" > "${_gpg_info}"
}

_gpg_get_key_id() {
    echo $(gpg -k | grep "^ " |  sed -e 's/^\s*//' -e '/^$/d')
}

_gpg_get_shortkey_id() {
    echo $(gpg -k --keyid-format short | grep -E "^sub" | awk '{print $2}' | awk -F'/' '{print $2}')
}

gpg_export() {
    echo "Exporting gpg keys"
    [ ! -d "${_gpg_export}" ] && mkdir -p "${_gpg_export}"

    _gpg_id=$(_gpg_get_key_id)

    [ -f "${_gpg_info}" ] && gpg_show_password

    pushd "${_gpg_export}"
    gpg -a --output gpg-key.asc --armor --export "${_gpg_id}"
    gpg -a --output gpg-secret-key.asc --armor --export-secret-keys "${_gpg_id}"
    popd

    [ -f "${_gpg_info}" ] && cp -f "${_gpg_info}" "${_gpg_export}/gpg_info"
}

gpg_show_password() {
    _gpg_pass="$(cat "${_gpg_info}" | tail -n 1)" || return 1

    dialog --title "GPG-Password" --infobox "${_gpg_pass}" 3 40
    read -p "Copy the Password from above. Press <Key> to continue ..."
}

gpg_import() {
    [ -f "${_gpg_info}" ] && gpg_show_password

    pushd "${_gpg_export}"
    gpg --import gpg-key.asc
    gpg --import --allow-secret-key-import gpg-secret-key.asc

    _gpg_id=$(_gpg_get_key_id)
    gpg_set_trust "${_gpg_id}"
    popd

    return 0
}

gpg_set_duply_gpg_keys() {
    local _gpg_id=$(_gpg_get_key_id)
    local _gpg_id_short=$(_gpg_get_shortkey_id)

    profiles=( "data" )
    for profile in "${profiles[@]}";do
    [ ! -z _gpg_id ] && [ -f /root/.duply/${profile}/conf ] && \
	local key="GPG_KEY"; local shortkey="GPG_KEY_SIGN"; \
	sed -i -e "s|^${key}=.*|${key}=${_gpg_id}|g" \
	       -e "s|^${shortkey}=.*|${shortkey}=${_gpg_id_short}|g" \
	/root/.duply/${profile}/conf
    done

    return 0
}

gpg_start_gpg_agent() {
    [ -f "${_gpg_agent_conf}" ] && \
	cat  "${_gpg_agent_conf}" | grep allow-loopback-pinentry 2>&1 > /dev/null && \
	rval=$? || rval=1

    # need this to get gpg working within docker and alpine
    [[ $rval != 0 ]] &&	echo allow-loopback-pinentry > "${_gpg_agent_conf}"


    gnupginf="${_gpg_folder}/gpg-agent-info"
    if pgrep -u "${USER}" gpg-agent >/dev/null 2>&1; then
	eval "$(cat $gnupginf)"
	eval "$(cut -d= -f1 < $gnupginf | xargs echo export)"
    else
	eval "$(gpg-agent --homedir /gpg_home --use-standard-socket --daemon)"
    fi
}

case $1 in
    "export")
	gpg_export
	;;
    "get-key")
	_gpg_get_key_id
	;;
    *)
	gpg_start_gpg_agent
	gpg_gen
	gpg_set_duply_gpg_keys
	;;
esac

exit 0
