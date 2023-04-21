#!/bin/bash

##############################################################################################
# cronjob to automate tarsnap backups                                                        #
# tar! Oh, snap!, stylized as `tarohsnap` is released with the MIT license                   #
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
snap_day=$(date +%Y%m%d)
snap_month=$(date +%Y%m)
snap_year=$(date +%Y)
back_today=$(uname -n)-$(date +%Y.%m.%d)-daily
back_month=$(uname -n)-$(date +%Y.%m.%B)-monthly
back_year=$(uname -n)-$(date +%Y)-annual
to_day=$(date +%j)
to_morrow=$(TZ=$(date +%Z) date +%d)
end_year=$(date -d "Dec 31" +%j) # Annual backup, Grandparent, scheduled for end-of-year
hold_days=7                    # Arbitrary number of daily backups to keep
hold_months=12                 # Keep 1 year of rolling monthly backups
tmp_file=$(mktemp)
tmp_hold=$(mktemp)
line_size_max=1000             # Arbitrary max number of lines in log file
line_size_min=50               # Arbitrary min number of lines in log file
back_targets="/path/to/backup/one /path/to/backup/two"

# Error checking
# Check for and fail if `root` user detected
if [ $(id -u) = 0 ]; then
    logger -p user.info "ERROR: root DETECTED! tarohsnap IS NOT DESIGNED TO BE RUN AS root USER! EXITING!"
    exit 1
# Check if tarsnap is installed
elif ! [ -x "$(command -v $oh_snap)" ]; then
    logger -p user.info "ERROR: COULD NOT LOCATE tarsnap ON YOUR SYSTEM!"
    exit 1
fi

# Check for tarsnap user location
if [ ! -e ${ohsnap_loc} ]; then
    mkdir -p ${ohsnap_loc}
elif [ ! -e ${log_loc} ]; then
    mkdir -p ${log_loc}
fi

${oh_snap} --list-archives | sort > "$tmp_file"
mapfile -t yarchives < "$tmp_file"

# Backup routine 
# Grandparent (annual) - Parent (monthly) - Child (daily)
printf "%s\n" "**********" >> ${logfile}

# Annual backup
if [ $to_day -eq $end_year ]; then
    if cat $tmp_file | grep $back_year > /dev/null; then
        printf "%s\n" "Annual backup for $snap_year already exists" >> ${logfile}
    else
        printf "%s\n" "Initiating ANNUAL backup..." >> ${logfile}
        ${oh_snap} -cf ${back_year} $back_targets > /dev/null
        printf "%s\n" "    Annual backup for $snap_year complete" >> ${logfile}
        printf "%s\n" "    NOTE: Annual backup will be scheduled for 31 December for the current year"
        printf "%s\n" "          The first annual backup is created from current files and will be overwritten"
    fi
else
    adays=$(( $end_year - $to_day ))
    printf "%s\n" "$adays days remaining until annual backup on 31 December ${snap_year}" >> ${logfile}
fi

# Monthly backup
if [ $to_morrow -eq 1 ]; then   #Do monthly backups on last day of the current month
    if cat $tmp_file | grep $back_month > /dev/null; then
        printf "%s\n" "Monthly backup for $(date +%B) $(date +%Y) already exists" >> ${logfile}
    else
        printf "%s\n" "Initiating MONTHLY backup..." >> ${logfile}
        ${oh_snap} -cf ${back_month} $back_targets > /dev/null
        printf "%s\n" "    Monthly backup for $(date +%B) $(date +%Y) complete" >> ${logfile}
    fi
fi

# Daily backup
if cat $tmp_file | grep ${back_today} > /dev/null; then
    printf "%s\n" "Daily backup for $(date +%A), $(date +%B) $(date +%d), $(date +%Y) already exists" >> ${logfile}
else
    printf "%s\n" "Initiating DAILY backup..." >> ${logfile}
    ${oh_snap} -cf ${back_today} $back_targets > /dev/null
    printf "%s\n" "    Daily backup for $(date +%A), $(date +%B) $(date +%d), $(date +%Y) completed" >> ${logfile}
fi
printf "%s\n" >> ${logfile}

# Delete archives older than $hold_days and $hold_months

# Monthly archive deletion > $hold_months
mapfile -t marchives < "$tmp_file"
mremove=$(( ${#marchives[@]} -keep ))
mtargets=( $(head -n "$mremove" "$tmp_file" | grep monthly | sort -r) )

if (( ${#mtargets[@]} > $hold_months )); then
    printf "%s\n" "Monthly archives to delete:" >> ${logfile}
    printf "%s\n" "    ${mtargets[@]:$hold_months}" >> ${logfile}

    for marchives in "${mtargets[@]:$hold_months}"; do
        ${oh_snap} -d --no-print-stats -f "$marchives" > /dev/null
    done

    printf "%s\n" "    Monthly archives successfully deleted" >> ${logfile}
else
    printf "%s\n" "No monthly archives to delete" >> ${logfile}
fi

# Daily archive deletion > $hold_days
mapfile -t darchives < "$tmp_file"
dremove=$(( ${#darchives[@]} -keep ))
dtargets=( $(head -n "$dremove" "$tmp_file" | grep daily | sort -r) )

if (( ${#dtargets[@]} > $hold_days )); then
    printf "%s\n" "Daily archives to delete:" >> ${logfile}
    printf "%s\n" "    ${dtargets[@]:$hold_days}" >> ${logfile}

    for darchives in "${dtargets[@]:$hold_days}"; do
        ${oh_snap} -d --no-print-stats -f "$darchives" > /dev/null
    done

    printf "%s\n" "    Daily archives successfully deleted" >> ${logfile}
else
    printf "%s\n" "No daily archives to delete" >> ${logfile}
fi
printf "%s\n" >> ${logfile}

# List current archives
${oh_snap} --list-archives | sort > "$tmp_hold"

# Annual archives
mapfile -t yannual < "$tmp_hold"
yleft=$(( ${#yannual[@]} -keep ))
yprint=( $(head -n "$yleft" "$tmp_hold" | grep annual | sort) )

printf "%s\n" "List of current ANNUAL archives:" >> ${logfile}
for yannual in "${yprint[@]}"; do
    printf "%s\n" "    $yannual" >> ${logfile}
done

# Monthly archives
printf "%s\n" "List of current MONTHLY archives::" >> ${logfile}
mapfile -t mmonthly < "$tmp_hold"
mleft=$(( ${#mmonthly[@]} -keep ))
mprint=( $(head -n "$mleft" "$tmp_hold" | grep monthly | sort) )

for mmonthly in "${mprint[@]}"; do
    printf "%s\n" "    $mmonthly" >> ${logfile}
done

# Daily archives
printf "%s\n" "List of current DAILY archives:" >> ${logfile}
mapfile -t ddaily < "$tmp_hold"
dleft=$(( ${#ddaily[@]} -keep ))
dprint=( $(head -n "$dleft" "$tmp_hold" | grep daily | sort) )

for ddaily in "${dprint[@]}"; do
    printf "%s\n" "    $ddaily" >> ${logfile}
done

# Control the log file size
wc -l ${logfile} | ( read lcnt other
if [ $lcnt -gt $line_size_max ]; then
    ((start=$lcnt-$line_size_min))
    printf "%s\n" "Trimming logfile" >> ${logfile}
    tail +$start ${logfile} > ${tmplog}
    mv ${tmplog} ${logfile}
else
    printf "%s\n" "Logfile does not need trimmed" >> ${logfile}
fi )

printf "%s\n" "Backup completed for $snap_day" >> ${logfile}
printf "%s\n" "**********" >> ${logfile}

# Clean up after ourselves
rm -rf "$tmp_file"
rm -rf "$tmp_hold"

exit 0                          # Exit gracefully
#EOF
