tarohsnap
===============

Description & Roadmap
--------------------

`tarohsnap` is a shell script cron job that creates backups with tarsnap.
The name is a play on the words: `Tar? Oh snap!` and, of course `tarnsap`

My current design goals are:

- Backup specific files/directories using variables within the script
- Daily backup schedule
- focus on bash functionality first, then more portable shell code later
- One backup per day
- Deletes archived files in a given length of time
- Keeps a log file of all activities performed
- Started error handling 04 May 2020, specifically exiting if tarsnap does not exist on the system and logging it to the system's log

Future goals:

- More shell agnostic design
- Incorporate conf file, `/etc/tarohsnap.conf` to house user-defined variables
- Error handling
- System logfile location rather than local
- Either local system notification on error/completion or email notification

Usage
--------------------

1. Customize `tarohsnap.sh` and place it in a folder that's in the system's path
   such as `/usr/bin/local/tarohsnap.sh`
2. Setup a cron job to run daily

Note:
--------------------
Example of an archive name:

     $hostname-20200323

This script assumes that you have tarsnap installed, configured and running; it further assumes that a regular, unprivileged user will invoke it through `crontab -e`

I have also included my dotfile, tarsnaprc, which I create at $USER/.tarsnaprc as an example; I would replace `$USER` with your actual user name

Warning
--------------------
This script is provided as-is; I don't warranty or guarantee that it will or will not delete your archives; modify it for your system(s)
