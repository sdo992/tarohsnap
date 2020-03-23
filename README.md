tarohsnap
===============

Description & Roadmap
--------------------

`tarohsnap` is a shell script cron job that creates backups with tarsnap.

My current design goals are:

- Backup specific files/directories using variables within the script
- Daily backup schedule
- focus on bash functionality first, then more portable shell code later
- One backup per day
- Deletes archived files in a given length of time
- Keeps a log file of all activities performed

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

Example of an archive name:

     `hostname-20200323`
