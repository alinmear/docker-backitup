#!/bin/bash

declare -A config_overrides

_env_variable_prefix=$1
[ -z ${_env_variable_prefix} ] && return 1


IFS=" " read -r -a _config_files <<< $2

# dispatch env variables
# workarround for whitespaces in env vars
printenv | grep "$_env_variable_prefix" > /tmp/override_config.tmp
env_arr=()
while read line; do
    env_arr+=( "$line" )
done < /tmp/override_config.tmp

rm -f /tmp/override_config.tmp

# for env_variable in $(printenv | grep $_env_variable_prefix);do
for env_variable in "${env_arr[@]}";do
    # get key
    # IFS not working because values like ldap_query_filter or search base consists of several '='
    # IFS="=" read -r -a __values <<< $env_variable
    # key="${__values[0]}"
    # value="${__values[1]}"
    key=$(echo $env_variable | cut -d "=" -f1)
    key=${key#"${_env_variable_prefix}"}
    # get value
    value=$(echo $env_variable | cut -d "=" -f2-)

    config_overrides[$key]=$value
done

for f in "${_config_files[@]}"
do
    if [ ! -f "${f}" ];then
	echo "Can not find ${f}. Skipping override" 
    else
	for key in ${!config_overrides[@]} 
	do
	    [ -z $key ] && echo -e "\t no key provided" && return 1
	    
	    sed -i -e "s|^${key}=.*|${key}=${config_overrides[$key]}|g" \
		${f}
	done
    fi
done

