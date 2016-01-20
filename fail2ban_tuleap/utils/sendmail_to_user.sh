#!/bin/bash
#Authors:Fares Ben Khalifa
#        Mohamed Rafik BEN MANSOUR
#Created in: 15/12/2015
#Version No: V1.0

#Change description (if any):

#Purpose: Send mail to gerrit admin and banned user( meant to be runned  after a user ban)

source ban_gerrit_tuleap.conf

#-- testing whether a user is in the  whitelist or not
is_non_interactive()
{
    user=$1
    login=$2
    password=$3
    serv=$4
    is_non_interactive=0
    username="\"username\": \"$user\""
    res=`curl -k -XGET -s /dev/null --digest -u $login:$password $serv/a/groups/$gerrit_non_interactive_group_name/members`
    if [[ $res = *$username* ]]
    then
        is_non_interactive=1
    fi
}

#-- testing if user is in whitelist or not
is_whitelisted()
{
    whitelist=$1
    user=$2
    is_whitelisted=0
    i=0
    while [[ $is_whitelisted = 0 ]] && [[ $i -lt ${#whitelist[@]} ]]
    do
        if [ $user = ${whitelist[$i]} ]
        then
            is_whitelisted=1
        else
            (( i++ ))
        fi
    done
}

#-- Main
#------------------------------------------------
    #-- Initialized parameters section (please do not change this section)
    #------------------------------------------------
    #-- diplay help message parameter
    need_help=0

    #-- email params
    sender_name=$1
    recipient_mail=$2
    sender_mail=$3

    #-- ban related infos
    bantime=$4
    attempts=$5

    #-- user to ban
    user_to_ban=$6

    #-- ip address of the user to ban
    ip=$7

    #-- ip address of the user to ban
    server=$8

    #-- jail parameter (can be 1 if you called this script in the non_interactive user jail or 0 if not) this one is an exlusive parameter to gerrit.
    #-- used to check the jail nature and the user nature returned
    non_interactive_user_jail=${9-2}
    #------------------------------------------------

if [[ $# = 9 && $server = "gerrit"]]
then
    whitelist=("${whitelist[@]}")
    is_whitelisted $whitelist $user_to_ban
    if [ $is_whitelisted -eq 0 ]
    then
        conditions_verified=1
        if [ $non_interactive_user_jail -lt 2 ]
        then
            is_non_interactive $user_to_ban $admin_login $password_gerrit $serv_gerrit
            if [[ $is_non_interactive -ne $non_interactive_user_jail ]]
            then
                conditions_verified=0
            fi
        fi
        if [ $conditions_verified -eq 1 ]
        then
            echo -e "Subject: [Fail2Ban] $sender_name: User ban
Date: `date`
From: $HOST <$sender_mail>
To: $recipient_mail\n
Hi,\n
The user $user_to_ban  has just been banned by Fail2Ban after
$attempts attempts against $sender_name.\n
Here is more informations :
- ShortName: $user_to_ban
- Email: `cd /etc/fail2ban/utils && sh ./extract_usermail.sh $user_to_ban`
- BanTime: $bantime
- IP: $ip
\nRegards,
Fail2Ban" | /usr/sbin/sendmail -f $sender_mail $recipient_mail

            recipient_mail=`cd /etc/fail2ban/utils && ./extract_usermail.sh $user_to_ban`
            echo -e "Subject: [Fail2Ban] $sender_name: User ban
Date: `date`
From: $HOST <$sender_mail>
To: $recipient_mail\n
Hi,\n
The user $user_to_ban  has just been banned by Fail2Ban after
$attempts attempts against $sender_name.\n
It'll be unbanned after $bantime.
\nRegards,
Fail2Ban" | /usr/sbin/sendmail -f $sender_mail $recipient_mail
        fi
    fi
elif [[ $# = 8 && $server = "tuleap"]]
then
    whitelist=("${whitelist[@]}")
    is_whitelisted $whitelist $user_to_ban
    if [ $is_whitelisted -eq 0 ]
    then
        echo -e "Subject: [Fail2Ban] $sender_name: User ban
Date: `date`
From: $HOST <$sender_mail>
To: $recipient_mail\n
Hi,\n
The user $user_to_ban  has just been banned by Fail2Ban after
$attempts attempts against $sender_name.\n
Here is more informations :
- ShortName: $user_to_ban
- Email: `cd /etc/fail2ban/utils && sh ./extract_usermail.sh $user_to_ban`
- BanTime: $bantime
- IP: $ip
\nRegards,
Fail2Ban" | /usr/sbin/sendmail -f $sender_mail $recipient_mail

            recipient_mail=`cd /etc/fail2ban/utils && ./extract_usermail.sh $user_to_ban`
            echo -e "Subject: [Fail2Ban] $sender_name: User ban
Date: `date`
From: $HOST <$sender_mail>
To: $recipient_mail\n
Hi,\n
The user $user_to_ban  has just been banned by Fail2Ban after
$attempts attempts against $sender_name.\n
It'll be unbanned after $bantime.
\nRegards,
Fail2Ban" | /usr/sbin/sendmail -f $sender_mail $recipient_mail
    fi
else
    need_help=1
fi

if [ $need_help -eq 1 ]
then
    echo -e "Please respect this form\n$0 [app name] [recipient mail] [sender mail] [bantime] [attempts] [matches] [non_interactive_user_jail (0 or 1)] [ip address]"
fi
exit 0
