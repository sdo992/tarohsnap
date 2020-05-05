#!/bin/bash

# cronjob run daily

# Variables
oh_snap=$(which tarsnap)
snap_date=$(date +%Y%m%d)
hold_days=3 # Arbitrary number of backups to hold
snap_loc=/home/$USER/.tarsnap
log_loc=/home/$USER/.tarsnap/logs
tlog=${log_loc}/tlog
tmp_log=${log_loc}/tmplog
back_today=$(uname -n)-$(date +%Y%m%d)
tmpfile=$(mktemp)
back_targets="/path/to/dir1 /path/to/dir2"
line_size_max=100 # Arbitrary upper number of lines in $tlog
line_size_min=50 # Arbitrary lower number of lines in $tlog

# Check if tarsnap is installed
if ! [ -x "$(command -v $oh_snap)" ]; then
    logger -p user.info "ERROR: COULD NOT LOCATE tarsnap ON YOUR SYSTEM"
    exit 1
fi

# Check if directory & log file exist, if not, create them
if [ ! -e ${snap_loc} ]; then
    mkdir -p ${snap_loc}
elif [ ! -e ${log_loc} ]; then
    mkdir -p ${log_loc}
    printf "%s\n" "TARSNAP INITIAL DIRECTORY AND LOG FILE CREATED ON $snap_date" > ${tlog}
fi

printf "%s\n" "**********" >> ${tlog}
printf "%s\n" "TARSNAP BACKUP FOR $snap_date" >> ${tlog}
# Backup if/else statement
if ${oh_snap} --list-archives | sort | grep ${back_today} > /dev/null; then
    printf "%s\n" "    BACKUP FOR $back_today ALREADY COMPLETED" >> ${tlog}
    printf "%s\n" "    EXITING SCRIPT" >> ${tlog}
    printf "%s\n" "**********" >> ${tlog}
    exit 0 # Stop here if backup already complete
else
    printf "%s\n" "    BACKUP FOR $back_today INITIATED" >> ${tlog}
    ${oh_snap} -cf ${back_today} $back_targets >> ${tlog}
    printf "%s\n" "    BACKUP COMPLETE for $back_today" >> ${tlog}
fi

# Delete $hold_days number of days of archives
${oh_snap} --list-archives | sort > "$tmpfile"
mapfile -t archives < "$tmpfile"
remove=$(( ${#archives[@]} - keep ))
targets=( $(head -n "$remove" "$tmpfile" | sort -r) )

if (( ${#targets[@]} > $hold_days )); then
    printf "%s\n" "    ARCHIVES TO DELETE:" >> ${tlog}
    printf "%s\n" "    ${targets[@]:$hold_days}" >> ${tlog}

    for archives in "${targets[@]:$hold_days}"; do
        ${oh_snap} -d --no-print-stats -f "$archives" > /dev/null
    done && printf "%s\n" "    ARCHIVES SUCCESSFULLY DELETED" >> ${tlog}

    printf "\n%s\n" "    REMAINING ARCHIVES: " >> ${tlog}
    ${oh_snap} --list-archives | sort >> ${tlog}
else
    printf "%s\n" "    NO ARCHIVES TO DELETE" >> ${tlog}
fi

# Control log file size
wc -l ${tlog} | ( read lcnt other

if [ $lcnt -gt $line_size_max ]; then
    ((start=$lcnt-$line_size_min))
    printf "%s\n" "    TRIMMING CURRENT LOG FILE" >> ${tlog}
    tail +$start ${tlog} > ${tmp_log}
    mv ${tmp_log} ${tlog}
else
    printf "%s\n" "    NOTHING TO TRIM" >> ${tlog}
fi )

# End of script
printf "%s\n" "BACKUP SCRIPT COMPLETE FOR $back_today" >> ${tlog}
printf "%s\n" "**********" >> ${tlog}
printf "%s\n" >> ${tlog}

rm "$tmpfile"
exit 0
# EOF
