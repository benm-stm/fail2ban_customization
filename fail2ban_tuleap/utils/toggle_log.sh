#!/bin/bash

#Created by: MED RAFIK BEN MANSOUR
#Created on: 15/10/2015
#Version No: V1.0

#Change description (if any):

#Purpose: Toggle log files to permit the parse of fail2ban on the newly created gitolite file and restart fail2ban
#to avoid having permission issues try to cron this script as a root user

#------------------------------------------------
#-- Section to be filled
#------------------------------------------------
fail2ban_dir=/etc/fail2ban
logs_dir=/var/lib/gitolite/.gitolite/logs
current_date=$(date +"%Y-%m-%d")
credentials=660
owner_group=gitolite:gitolite
#------------------------------------------------

log_file="$logs_dir/gitolite-$current_date.log"
#-- Replace the log name in fail2ban jail
sed -i "/gitolite-*.log/c\logpath  = $log_file" $fail2ban_dir/jail.conf

#create log file if it does not exist
if [ -f "$log_file" ]
then
        #-- Restart fail2ban so the conf will take place
        /sbin/service fail2ban restart
else
        touch $log_file
        chmod $credentials $log_file
        chown $owner_group $log_file
        /sbin/service fail2ban restart
fi

exit 0
