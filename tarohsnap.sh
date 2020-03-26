#!/bin/bash

# cronjob run daily

# Variables
oh_snap=/usr/local/bin/tarsnap
snap_date=$(date +%Y%m%d)
hold_days=3
log_loc=/home/$USER/.tarsnap/logs
tlog=${log_loc}/tlog
back_today=$(uname -n)-$(date +%Y%m%d)
tmpfile=$(mktemp)
back_targets="/path/to/backup1 /path/to/backup2"

# Check if directory exists, if not, create it and the log file
if [ ! -e ${log_loc} ]; then
    mkdir $log_loc
    if [ ! -e ${tlog} ]; then
        printf "%s\n" "TARSNAP INTIAL DIRECTORY AND FILE CREATION $snap_date" > ${tlog}
        printf "%s\n" >> ${tlog}
    fi
fi

# Backup if/else statement
if ${oh_snap} --list-archives | sort | grep ${back_today} > /dev/null; then
    printf "%s\n" "**********" >> ${tlog}
    printf "%s\n" "BACKUP FOR $back_today ALREADY COMPLETED" >> ${tlog}
else
    printf "%s\n" "BACKUP FOR $back_today INITIATED" >> ${tlog}
    ${oh_snap} -cf ${back_today} $back_targets >> ${tlog}
    printf "%s\n" "BACKUP COMPLETE for $back_today" >> ${tlog}
fi

# Delete $hold_days number of days of archives
${oh_snap} --list-archives | sort > "$tmpfile"
mapfile -t archives < "$tmpfile"
remove=$(( ${#archives[@]} - keep ))
targets=( $(head -n "$remove" "$tmpfile" | sort -r) )

if (( ${#targets[@]} > $hold_days )); then
    printf "%s\n" "ARCHIVES TO DELETE:" >> ${tlog}
    printf "%s\n" "${targets[@]:$hold_days}" >> ${tlog}

    for archives in "${targets[@]:$hold_days}"; do
        ${oh_snap} -d --no-print-stats -f "$archives" > /dev/null
    done && printf "%s\n" "ARCHIVES SUCCESSFULLY DELETED" >> ${tlog}

    printf "\n%s\n" "REMAINING ARCHIVES: " >> ${tlog}
    ${oh_snap} --list-archives | sort >> ${tlog}
else
    printf "%s\n" "NO ARCHIVES TO DELETE" >> ${tlog}
fi

# End of script
printf "%s\n" "BACKUP SCRIPT COMPLETE FOR $back_today" >> ${tlog}
printf "%s\n" "**********" >> ${tlog}
printf "%s\n" >> ${tlog}

rm "$tmpfile"
# EOF
