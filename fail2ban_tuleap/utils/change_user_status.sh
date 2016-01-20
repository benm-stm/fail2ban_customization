#!/bin/bash

#Created in: 21/12/2015
#Version No: V1.0
#Author: Fares Ben Khalifa
#        Mohamed Rafik BEN MANSOUR
#Change user status via api Rest for both gerrit and tuleap apps

source ban_gerrit_tuleap.conf

#-- testing whether a user is in the  whitelist or not
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

#-- testing if user is in the non interactive user group
is_non_interactive()
{
    user=$1
    login=$2
    password=$3
    serv=$4
    gerrit_group_name=$5
    is_non_interactive=0
    username="\"username\": \"$user\""

    res=`curl -k -XGET -s /dev/null --digest -u $login:$password $serv/a/groups/$gerrit_group_name/members`
    if [[ $res = *$username* ]]
    then
        is_non_interactive=1
    fi
}

#-- logging
logit()
{
    echo "[$USER][`(date +"%m-%d-%Y-%T")`] : $1" >> $log_file
}

#-- Return the user id
getUserIdFromTuleap()
{
    login=$1
    password=$2
    serv=$3
    input_param=$4
    parameter=$5

    id=`curl -k -XGET -s /dev/null --header 'Content-type: application/json' -u $login:$password "$serv/api/users?query=%7B%22$input_param%22%3A%22$parameter%22%7D&limit=10&offset=3" | grep -oP "\"id\":\K.*?(?=,)"`
}

#-- Change the status of the tuleap user (ban or unban)
change_tuleap_user_status()
{
    serv=$1
    id=$2
    status_param=$3
    login=$4
    password=$5

    username=`curl -k -XGET -s /dev/null --header 'Content-type: application/json' -u $login:$password "$serv/api/users?query=%7B%22$input_param%22%3A%22$parameter%22%7D&limit=10&offset=3" | grep -oP "\"username\":\"\K.*?(?=\")"`
    res=`curl -k -X PATCH -s /dev/null --header 'Content-type: application/json' -d "{\"status\" : \"$status_param\"}" -u $login:$password $serv/api/users/$id`
    if [ $status_param = "S" ]
    then
        if [ $res = "true" ]
        then
            logit "$username has been banned on $serv"
        else
            logit "$username is already banned on $serv"
        fi
    else
        if [ $res = "true" ]
        then
            logit "$username has been unbanned on $serv"
        else
            logit "$username is active on $serv"
        fi
    fi
}

#-- Change the status of the gerrit user (ban or unban)
change_gerrit_user_status()
{
    parameter=$1
    user=$2
    password=$3
    serv=$4
    status_param=$5

    res=`curl -k --digest -X$status_param -s /dev/null -u $user:$password $serv/a/accounts/$parameter/active`
    if [[ $status_param = "DELETE" ]] && [[ $res = "" ]]
    then
        logit "$parameter has been banned on $serv"
    elif [[ $status_param = "PUT" ]]
    then
        logit "$parameter has been unbanned on $serv"
    fi
}

#-- Main

#-- diplay help message parameter
need_help=0

if [[ $# = 4 ]] && [[ $3  = "gerrit"  ]]
then
    #------------------------------------------------
    #-- Initialized parameters section (please do not change this section)
    #------------------------------------------------
    #-- User name to ban
    user_to_ban=$1

    #-- ban command passed (ban or unban)
    ban_command=$2

    #-- Nature of server passed (tuleap or gerrit)
    server_type=$3

    #-- jail parameter (can be 1 if you called this script in the non_interactive user jail or 0 if not)
    #-- used to check the jail nature and the user nature returned
    non_interactive_user_jail=$4
    #------------------------------------------------

    is_whitelisted $whitelist $user_to_ban
    if [ $is_whitelisted -eq 0 ]
    then
        is_non_interactive $user_to_ban $admin_login $password_gerrit $serv_gerrit $gerrit_non_interactive_group_name
        if [ $ban_command = "unban" ]
        then
            if [[ $is_non_interactive -eq $non_interactive_user_jail ]]
            then
                change_gerrit_user_status $user_to_ban $admin_login $password_gerrit $serv_gerrit PUT
            else
                logit "ERROR: incompatible jail\n"
            fi
        elif [ $ban_command = "ban" ]
        then
            if [[ $is_non_interactive -eq $non_interactive_user_jail ]]
            then
                change_gerrit_user_status $user_to_ban $admin_login $password_gerrit $serv_gerrit DELETE
            else
                logit "ERROR: incompatible jail\n"
            fi
        else
            need_help=1
        fi
    else
        logit "$parameter is in the whitelist, he can not be banned"
    fi
elif [[ $# = 3 ]] && [[ $3 = "tuleap"  ]]
then
    #------------------------------------------------
    #-- Initialized parameters section (please do not change this section)
    #------------------------------------------------
    #-- User name to ban
    user_to_ban=$1

    #-- ban command passed (ban or unban)
    ban_command=$2

    #-- Nature of server passed (tuleap or gerrit)
    server_type=$3

    #-- jail parameter (can be 1 if you called this script in the non_interactive user jail or 0 if not)
    #-- used to check the jail nature and the user nature returned
    non_interactive_user_jail=$4
    #------------------------------------------------

    is_whitelisted $whitelist $user_to_ban
    if [ $is_whitelisted -eq 0 ]
    then
        if [ $ban_command = "unban" ]
        then
            status="A"
            getUserIdFromTuleap $admin_login $password_tuleap $serv_tuleap $input_param $1
            change_tuleap_user_status $serv_tuleap $id $status $admin_login $password_tuleap
        elif [ $ban_command = "ban" ]
        then
            status="S"
            getUserIdFromTuleap $admin_login $password_tuleap $serv_tuleap $input_param $1
            change_tuleap_user_status $serv_tuleap $id $status $admin_login $password_tuleap
        else
            need_help=1
        fi
    else
        logit "$parameter is in the whitelist, he can not be banned"
    fi
else
    need_help=1
fi

if [ $need_help -eq 1 ]
then
    echo -e "Please respect this form\nTo ban or unban tuleap user: $0 [username] [ban or unban] [tuleap] \nTo ban or unban gerrit user: $0 [username] [ban or unban] [gerrit] [non_interactive_user_jail (0 or 1)]"
fi
exit 0
