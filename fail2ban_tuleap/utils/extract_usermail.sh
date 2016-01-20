#!/bin/bash
#Created by: MED RAFIK BEN MANSOUR
#            Fares BEN KHALIFA
#Created in: 13/01/2016
#Version No: V1.0

#Change description (if any):

#Purpose: Send customized mail to users

source ban_gerrit_tuleap.conf

#-- Retrieve a specified user data from LDAP
retrieve_given_data()
{
    result=`ldapsearch -D "$binddn" -w "$passwd" -b "$sys_ldap_dn" -x -LLL -h $sys_ldap_server "(|(cn=$1)(uid=$1)(st-eduid=$1))" $2`
}

#-- retrieve an account data directly from a user account or from a generic account
retrieve_user_data()
{
    user=$1
    filter="employeetype"
    retrieve_given_data $user $filter
    isApplication=`echo $result| grep $filter | sed 's/.*\: \(.*\)/\1/' | sed 's/,.*//' | sed 's/.*=//'`
    #-- The account is generic get the user's direct email
    if [ ! -z $isApplication  ] && [ $isApplication != "st" ]
    then
        filter="manager"
        retrieve_given_data $user $filter
        user=`echo $result| grep $filter | sed 's/.*\: \(.*\)/\1/' | sed 's/,.*//' | sed 's/.*=//'`
    fi
    #-- get the email of the user owning the generic account
    filter=$2
    retrieve_given_data $user $filter
    res=`echo $result | grep $filter | sed 's/.*\: \(.*\)/\1/'`
    echo $res
}

#-- Main
if [ $# -ge 1 ] && [ $# -le 2 ] && [ "$1" != "--help" ]
then
    #------------------------------------------------
    #-- Initialized parameters section (please do not change this section)
    #------------------------------------------------
    #--User to search on
    user=$1

    #-- Ldap filter
    fields_filter=${2-mail}
    #------------------------------------------------

    retrieve_user_data $user $fields_filter
else
    echo -e "Usage:\t$0 [user cn, uid or eduid] [wanted field]"
fi

exit 0
