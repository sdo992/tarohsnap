#!/bin/bash

##############################################################################################
# cronjob to automate tarsnap backups                                                        #
# tar! Oh, snap!, stylized as `tarohsnap` is released with a GPL V3 license                  #
# see: https://www.gnu.org/licenses/gpl-3.0.en.html                                          #
# for any questions                                                                          #
#                                                                                            #
# Please visit https://github.com/sdo992/tarohsnap for the latest updates                    #
#                                                                                            #
# Install the script in a working path; for example: `/usr/local/bin/tarohsnap.sh`           #
# You have to run `$> sudo chmod +x /usr/local/bin/tarohsnap.sh` to make it executable       #
# Setup with `crontab -e` or similar, based on system setup                                  #
#                                                                                            #
# This script assumes that tarsnap is setup to be used by a regular user and not root        #
# and that a tarsnaprc is set up somewhere that defines tarsnap behavior;                    #
# It creates a local tarsnap directory in `$HOME/.tarsnap` and stores the logs               #
# in a subdirectory there                                                                    #
#                                                                                            #
# Any hard failures will be written to the system logs; please check your distribution's     #
# log file setup and location                                                                #
##############################################################################################

# Variables
oh_snap=/usr/local/bin/tarsnap  # Change to fit your installation
ohsnap_loc=/home/$USER/.tarsnap # Change to fit your system
log_loc=${ohsnap_loc}/logs
logfile=${log_loc}/ohsnap.log
tmplog=${log_loc}/tmplog.log
snap_date=$(date +%Y%m%d)
back_today=$(uname -n)-$(date +%Y%m%d)
hold_days=3                    # Arbitrary number of backups to keep
tmp_file=$(mktemp)
tmp_hold=$(mktemp)
line_size_max=1000             # Arbitrary max number of lines in log file
line_size_min=50               # Arbitrary min number of lines in log file
back_targets="/path/to/backup/one /path/to/backup/two"

# Check for and fail if `root` user detected
if [ $(id -u) = 0 ]; then
    logger -p user.info "ERROR: root DETECTED! tarohsnap IS NOT DESIGNED TO BE RUN AS root USER! EXITING!"
    exit 1
# Check if tarsnap is installed
elif ! [ -x "$(command -v $oh_snap)" ]; then
    logger -p user.info "ERROR: COULD NOT LOCATE tarsnap ON YOUR SYSTEM!"
    exit 1
fi

# Check for tarsnap location
if [ ! -e ${ohsnap_loc} ]; then
    mkdir -p ${ohsnap_loc}
elif [ ! -e ${log_loc} ]; then
    mkdir -p ${log_loc}
fi

# Start backup routine
printf "%s\n" "**********" >> ${logfile}
printf "%s\n" "TARSNAP BACKUP FOR $snap_date" >> ${logfile}

if ${oh_snap} --list-archives | sort | grep ${back_today} > /dev/null; then
    printf "%s\n" "    BACKUP FOR $back_today ALREADY COMPLETED" >> ${logfile}
    # printf "%s\n" "    EXITING!" >> ${logfile}
    # printf "%s\n" "**********" >> ${logfile}
    # exit 0                    # Stop here and exit gravefully
else
    printf "%s\n" "    BACKUP FOR $back_today INITIATED..." >> ${logfile}
    ${oh_snap} -cf ${back_today} $back_targets >> ${logfile}
    printf "%s\n" "    BACKUP COMPLETED FOR $back_today" >> ${logfile}
fi

# Start archive delete routine
${oh_snap} --list-archives | sort > "$tmp_file"
mapfile -t archives < "$tmp_file"
remove=$(( ${#archives[@]} -keep ))
targets=( $(head -n "$remove" "$tmp_file" | sort -r) )

if (( ${#targets[@]} > $hold_days )); then
    printf "%s\n" "    ARCHIVES TO DELETE:" >> ${logfile}
    printf "%s\n" "       ${targets[@]:$hold_days}" >> ${logfile}
    
    for archives in "${targets[@]:$hold_days}"; do
        ${oh_snap} -d --no-print-stats -f "$archives" > /dev/null
    done
    
    printf "%s\n" "    ARCHIVES SUCCESSFULLY DELETED" >> ${logfile}
else
    printf "%s\n" "    NO ARCHIVES TO DELETE" >> ${logfile}
fi

# Display remaining archives
printf "%s\n" "    LIST OF STORED ARCHIVES:" >> ${logfile}
${oh_snap} --list-archives | sort > "$tmp_hold"
mapfile -t keepers < "$tmp_hold"
left_over=$(( ${#keepers[@]} - keep ))
tokeep=( $(head -n "$left_over" "$tmp_hold" | sort) )

for keepers in "${tokeep[@]}"; do
    printf "%s\n" "       $keepers" >> ${logfile}
done

# Control the log file size
wc -l ${logfile} | ( read lcnt other

if [ $lcnt -gt $line_size_max ]; then
    ((start=$lcnt-$line_size_min))
    printf "%s\n" "    TRIMMING LOG FILE" >> ${logfile}
    tail +$start ${logfile} > ${tmplog}
    mv ${tmplog} ${logfile}
else
    printf "%s\n" "    NOTHING TO TRIM" >> ${logfile}
fi )

# Close the script down
printf "%s\n" "BACKUP SCRIPT COMPLETED FOR $back_today" >> ${logfile}
printf "%s\n" "**********" >> ${logfile}
printf "%s\n" >> ${logfile}

rm -rf "$tmp_file"              # Make sure we clean up after ourselves
rm -rf "$tmp_hold"              # Ditto

exit 0                          # Exit gracefully
# EOF