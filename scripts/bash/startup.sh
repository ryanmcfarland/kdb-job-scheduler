#!/bin/sh

## simple script to start-up revelant kdb process and define system variables

## SCH_HOME & SCH_LOGS needs to be defined at start-up

## hardcoding as I don't need to be fancy here - TODO
. ${SCH_HOME}/config/env/env.cfg
. ${SCH_HOME}/scripts/bash/log.sh

## Create default directories if they do not exist
test -d ${SCH_LOGS} || ( mkdir -p ${SCH_LOGS} && log_info "Creating $SCH_HOME" )
test -d ${SCH_LOGS_JOB} || ( mkdir -p ${SCH_LOGS_JOB} && log_info "Creating $SCH_HOME_JOB" )
test -d ${SCH_LOGS_PROCESS} || ( mkdir -p ${SCH_LOGS_PROCESS} && log_info "Creating $SCH_LOGS_PROCESS" )

## hard coded way to start-up processes
logname="${SCH_LOGS_PROCESS}/mainkdb.log"
cmd="nohup $q ${SCH_Q_CODE}/startup.q -init main -p 5001 > ${logname} 2>&1 &"
log_info "Running: ${cmd}"
eval "(${cmd})"

logname="${SCH_LOGS_PROCESS}/worker_test1_kdb.log"
cmd="nohup $q ${SCH_Q_CODE}/startup.q -init worker -p 5002 > ${logname} 2>&1 &"
log_info "Running: ${cmd}"
eval "(${cmd})"

logname="${SCH_LOGS_PROCESS}/worker_test2_kdb.log"
cmd="nohup $q ${SCH_Q_CODE}/startup.q -init worker -p 5003 > ${logname} 2>&1 &"
log_info "Running: ${cmd}"
eval "(${cmd})"

echo "Fin"
exit 0