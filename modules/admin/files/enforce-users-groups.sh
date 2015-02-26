#!/bin/bash

#TOOL EDITED FOR AUDITING. NO INVASIVE ACTION.

# This is a user garbage collection script that removes
# users who do not have a supplementary group that also have
# a UID above the ID_BOUNDARY. Removals are logged to syslog.
# with 'dryrun' as first arg exits 1 if cleanup is needed

ID_BOUNDRY='999'
ARCHIVE_DIR='/var/userarchive'
EXCLUDE=("nobody" "l10nupdate" "gmetric" "mwdeploy");

function log() {
    logger $1
    echo $1
}

in_array() {
    local haystack=${1}[@]
    local needle=${2}
    for i in ${!haystack}; do
        if [[ ${i} == ${needle} ]]; then
            return 0
        fi
    done
    return 1
}

if [ ! -d $ARCHIVE_DIR ]
    then
        log "creating new user files archive ${ARCHIVE_DIR}"
        mkdir $ARCHIVE_DIR
fi

#TMP
if [ "${1}" == "dryrun" ]
    then
        if [[ -e '/var/log/admincleanup' ]]
            then
                exit 0
        fi
fi

#TEMP
/bin/cat /dev/null > /var/log/admincleanup

IFS=$'\r\n' PASSWD_USERS=($(/usr/bin/getent passwd))
for var in "${PASSWD_USERS[@]}"
do
    username=`echo $var | cut -d ':' -f 1`
    uid=`echo $var | cut -d ':' -f 3`

    # A few global accounts of dubious nature are ignored
    if in_array EXCLUDE $username; then
        continue
    fi

    if [[ "$uid" -gt "$ID_BOUNDRY" ]]; then
        if [[ `/usr/bin/id $username` != *","* ]]; then
            #TEMP
            echo $var >> /var/log/admincleanup

        #NOT TO BE PUT IN SERVICE
        #log "${0} removing user/id: ${username}/${uid}"
        #/usr/sbin/deluser --remove-home --backup-to=$ARCHIVE_DIR $username &> /dev/null

        fi
    fi
done
