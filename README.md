tarohsnap
===============

<p align="left">
  <a aria-label="license" href="https://github.com/primer/css/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/primer/css.svg" alt="">
  </a>
</p>

Description & Roadmap
--------------------

`tarohsnap` is a shell script cron job that creates backups with tarsnap.
The name is a play on the words: `Tar? Oh snap!` and, of course `tarsnap`

This was first developed on a non-systemd system; changes may have to be made if you use a
systemd-based distro

My current design goals are:

- Backup specific files/directories using variables within the script
- Grandparent/Parent/Child backup schedule
- Focus on bash functionality first, then more portable shell code later
- One backup per day for $hold_days, 12 monthly backups and 1 annual backup
- Deletes archived files in a given length of time
- Keeps a log file of all activities performed
- Error handling 04 May 2020, specifically exiting if tarsnap does not exist on the system and logging it to the system's log

Future goals:

- More shell agnostic design
- Incorporate conf file, `/etc/tarohsnap.conf` to house user-defined variables
- Error handling
- System logfile location rather than local; tentatively, I am planning on `/var/log/tarohsnap.log`
  - To handle privilege escalation, I may have to break up the script into multiple files
  - Because of this, I may have to create an install procedure; not sure yet if I want to visit this with a shell script
- Either local system notification on error/completion or email notification ** IN PROGRESS **

Usage
--------------------

1. Customize `tarohsnap.sh` and place it in a folder that's in the system's path
   such as `/usr/bin/local/tarohsnap.sh`
2. Setup a cron job to run daily

Note:
--------------------
Example of archive names:

     $hostname-2020.03.23-daily
     $hostname-2020.03-March-monthly
     $hostname-2020-annual

This script assumes that you have tarsnap installed, configured and running; it further assumes that a regular, unprivileged user will invoke it through `crontab -e`

I have also included my dotfile, tarsnaprc, which I create at $USER/.tarsnaprc as an example; I would replace `$USER` with your actual user name

Warning
--------------------
This script is provided as-is; I don't warranty or guarantee that it will or will not delete your archives; modify it for your system(s)
