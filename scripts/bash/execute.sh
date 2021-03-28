#!/bin/sh

. /home/ryanm/.profile
. /home/ryanm/code/kdb-scheduler/scripts/bash/log.sh

## wrapper script to run the job commands on the host, enales better trackability of job success or failure

check_error ()
{
    if [ $? != 0 ];then
        echo ""
        log_err "JOB FAILURE - EXITING WITH ERROR 7"
        exit 7
    fi
}

while getopts "c:" arg; do
    case $arg in
        c) CMD=$OPTARG ;;
    esac
done

if [ -z $CMD ];then log_err "NO CMD HAS BEEN PROVIDED - EXITING WITH ERROR 6"; exit 6;fi

log_info "Running: ${CMD}"
echo ""
eval "(${CMD})"
check_error

echo ""
log_info "JOB SUCCESS"
exit 0