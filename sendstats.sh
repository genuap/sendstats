#!/bin/bash

# Default values for user configurable variables

_nc_graphite_destination=192.168.200.1

_nc_graphite_port=2003

_console_logging=false
_filename=sendscript
#_consolelogfile=/var/log/${_filename}/${_filename}.console.log

_db=graphite

_hostname=cumulus0

# Define column headers
columns=("Iface" "MTU" "RX_OK" "RX_ERR" "RX_DRP" "RX_OVR" "TX_OK" "TX_ERR" "TX_DRP" "TX_OVR" "Flg")

function send_to_db() {

        # Function will send the data in the first argument to a database as configured in the global variable _db

        # Supported databases defined in _db

        #       graphite

        #       logfile

        #       graphite+log

        #       none

        # argument 1: data to be sent

        local _data=$1



        if [ "${_db}" = "graphite" ] ; then

                # send the data to the graphite port and destination

                echo "${_data}" | nc "${_nc_graphite_destination}" "${_nc_graphite_port}"

        elif [ "${_db}" = "logfile" ] ; then

                # send the data the log file

                echo "${_data}"

        elif [ "${_db}" = "graphite+logfile" ] ; then

                # send the data to the graphite port and destination, and to the datalogfile

                echo "${_data}" | nc -N "${_nc_graphite_destination}" "${_nc_graphite_port}"

                echo "${_data}"

        elif [ "${_db}" = "none" ] ; then

                # don't do anything with the data

                :

        elif [ "${_db_not_supported}" != "logged" ] ; then

                # variable _db does not contain a supported database

                # send once the error to the log file

                _db_not_supported="logged"

                _db="none"

                log "[SENDTODB] ${_db} as database is not supported"

        fi

        return 0

}



function loop() {

        # function checks every second the bandwidth

        while true; do

                if ! ((_counter % 30)) ; then

                        # this block will run every half minute



                        # Read the table and store data in variables

                        netstat -i | while read -r line; do

                                if [[ $line == *"Kernel Interface table"* ]]; then

                                        continue  # Skip the header line

                                fi


                                # Remove leading and trailing whitespace
                                line="${line#"${line%%[![:space:]]*}"}"
                                line="${line%"${line##*[![:space:]]}"}"

                                # Split the line into variables

                                read -r -a values <<< "$line"

                                # Store values in variables with column headers as names

                                for ((i = 0; i < ${#columns[@]}; i++)); do
                                        col_name="${columns[$i]}"
                                        value="${values[$i]}"
                                        declare "${col_name}=${value}"
                                done


                                echo "${_hostname}.${Iface}.MTU ${MTU} $(date +%s)"
                                send_to_db "${_hostname}.${Iface}.MTU ${MTU} $(date +%s)"
                                send_to_db "${_hostname}.${Iface}.RX_OK ${RX_OK} $(date +%s)"
                                send_to_db "${_hostname}.${Iface}.RX_ERR ${RX_ERR} $(date +%s)"
                                send_to_db "${_hostname}.${Iface}.RX_DRP ${RX_DRP} $(date +%s)"
                                send_to_db "${_hostname}.${Iface}.RX_OVR ${RX_OVR} $(date +%s)"
                                send_to_db "${_hostname}.${Iface}.TX_OK ${TX_OK} $(date +%s)"
                                send_to_db "${_hostname}.${Iface}.TX_ERR ${TX_ERR} $(date +%s)"
                                send_to_db "${_hostname}.${Iface}.TX_DRP ${TX_DRP} $(date +%s)"
                                send_to_db "${_hostname}.${Iface}.TX_OVR ${TX_OVR} $(date +%s)"
                                send_to_db "${_hostname}.${Iface}.FLG ${FLG} $(date +%s)"

                        done





                        _counter=0

                fi



                _counter=$(( _counter + 1 ))

                sleep 1

        done

        return 0

}



function log() {

        # function will print the provided argument on the terminal and log it to the console log file if console logging is enabled

        # arguments: multiple strings



        echo "$*"

        if [[ "${_console_logging}" == "true" ]] ; then

                echo "$(date "+%F-%H:%M:%S") $*" >> "${_consolelogfile}"

        fi

        return 0
		}



function retrieve_pid() {

        # echo the process id of the running background process

        # if not running echo 0 as 0 is an invalid pid

        local _pid=0



        if [ -s "${_pidfile}" ] ; then

                # file ${_pid} is not empty

                _pid=$(cat "${_pidfile}")

                if ps -p "${_pid}" > /dev/null 2>&1 ; then

                        # ${_pid} is running process

                        echo "${_pid}"

                else

                        # ${_pid} is not a process id or not a running process

                        echo 0

                fi

        else

                # file ${_pid} is empty

                echo 0

        fi

        return 0

}



function status() {

        # log if the background process is running and return 0, or return 1 if not

        local _pid=0



        _pid=$(retrieve_pid)

        if [[ "${_pid}" -gt 0 ]] ; then

                # background process running

                log "[STATUS] Service ${_service} with pid=${_pid} running"

                return 0
				
        else

                # background process not running

                log "[STATUS] Service ${_service} not running"

                return 1

        fi

}







# Script need to run as root user

if [ "$(id -u)" -ne 0 ] ; then

        log "${_service} need to run as root user or as super user"

        exit 1

fi



# Prerequisite commands
#check_command awk basename bc grep sed nc nvme


#if(consolelogging==true)
  # create a log directory
#  mkdir -p /var/log/"${_filename}"
#  touch "${_consolelogfile}" >/dev/null 2>&1 || log "Error creating ${_consolelogfile}"
#fi

loop





