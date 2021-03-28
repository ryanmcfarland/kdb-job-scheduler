# $1 Type of log message
# $2 Message to output
log ()
{
    echo "["`date "+%Y.%m.%d %H:%M:%S.%3N"`" "`hostname`" "`whoami`"] ${1}: ${2}"
}

# $1 Message to output
log_err ()
{
    log "ERROR" "${1}"
}

# $1 Message to output
log_info ()
{
    log "INFO" "${1}"
}

# $1 Message to output
log_warn ()
{
    log "WARN" "${1}"
}