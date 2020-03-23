#!/bin/bash

# dcron daily bash Script

# Variables
tarsnap=/usr/local/bin/tarsnap
holdLength=3 # Number of days
logLocation=/home/$USER/.tarsnap/logs
tlog=${logLocation}/tlog
backToday=$(uname -n)-$(date +%Y%m%d)
backOld=`$tarsnap --list-archives | grep ${backToday} | sort -r | sed 1,${holdLength}d | sort | xargs -n 1`
backTargets="/path/to/backup1 /path/to/backup2"

# Check if directory exists, if not, create it and the log file
if [ ! -e ${logLocation} ]; then
    mkdir $logLocation
    if [ ! -e ${tlog} ]; then
        echo "TARSNAP INTIAL DIRECTORY AND FILE CREATION $(date +%Y%m%d)" > ${tlog}
        echo >> ${tlog}
    fi
fi

# Backup if/else statement
if ${tarsnap} --list-archives | sort | grep ${backToday} > /dev/null; then
    echo "**********" >> ${tlog}
    echo "BACKUP FOR $backToday ALREADY COMPLETED" >> ${tlog}
else
    echo "BACKUP FOR $backToday INITIATED" >> ${tlog}
    ${tarsnap} -cf ${backToday} $backTargets >> $tlog 2>&1
    echo "BACKUP COMPLETE for $backToday" >> ${tlog}
fi

# Control the size of the backups
echo "ATTEMPTING TO DELETE BACKUPS OLDER THAN $holdLength DAYS" >> ${tlog}
if [ -n "$backOld" ]; then 
    echo "Deleting the following backups: " >> ${tlog}
    echo "${backOld}" >> ${tlog}
    $tarsnap --list-archives | grep $backToday | sort -r | sed 1,${holdLength}d | sort | xargs -n 1 $tarsnap -df >> ${tlog} 2>&1
else
    echo "No backup files found to delete" >> ${tlog}
    echo "END OF DELETION SUBROUTINE" >> ${tlog}
fi

# End of script
echo "BACKUP SCRIPT COMPLETE FOR $backToday" >> ${tlog}
echo "**********" >> ${tlog}
echo >> ${tlog}

# EOF
