#!/bin/sh

## simple script to start-up revelant kdb process and define system variables

. /home/ryanm/code/kdb-scheduler/config/env/env.sh

. ${SCH_BASH}/log.sh

test -d ${SCH_LOGS} || ( mkdir -R ${SCH_LOGS} && log_info "Creating $SCH_HOME" )

