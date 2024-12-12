#################################################################
# Script to poll Infrastructure Management for approval status
#
# Version: 2.4
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Licensed Materials - Property of IBM
#
# ©Copyright IBM Corp. 2020.
#
#################################################################

#!/bin/sh

SetParams() {
   URL=$1
   OPTIONS=$5
   WAIT_TIME=$6
   FILE=$7
   SCHEDULE_DATE=$8

   AUTH=""
   USERNAME=$2
   PASSWORD=$3
   TOKEN=$4

   if [ "$TOKEN" == "DEFAULT_TOKEN" ]; then
      AUTH="Basic "
      AUTH+=$(printf $USERNAME:$PASSWORD | base64)
      echo "Token is empty, So using Username/Password for authentication."
   else
      AUTH="Bearer "
      AUTH+=$TOKEN
      echo "Token is not empty, So using Bearer token for authentication."
   fi

   # Log params
   printf "URL: %s\n" $URL
   printf "Options: %s\n" $OPTIONS
   printf "Wait Time: %s\n" $WAIT_TIME
   printf "File Path: %s\n" $FILE
   printf "Schedule Time: %s\n" $SCHEDULE_TIME
}

PollInfrastructureManagement() {
   # Set params
   SetParams $1 $2 $3 $4 $5 $6 $7 "$8"

   printf "Start PollInfrastructureManagement"
   printf "Approval Status: %s\napproved\n"
   result="approved"

   #schedule_date=$(date -d "+2 minutes" +"%Y-%m-%d %H:%M")
   schedule_date="$8"
   schedule_ts=$(date -d "$schedule_date" +%s)

   printf "Schedule Date : %s\n" "$schedule_date"
   printf "Schedule Timestamp: %s\n" "$schedule_ts"

   current_date=$(date +%s)
   printf "Current Date: %s\n" "$current_date"
   while [ "$(date +%s)" -lt "$schedule_ts" ]; do
      printf "While Date: %s\n" $date
      date=$(date +"%d/%m/%Y %H:%M")
      sleep $WAIT_TIME
   done

   printf "Final Date: %s\n" $date
   printf "Approval Status: %s\n" $result
   printf $result >$FILE
}

PollInfrastructureManagement $1 $2 $3 $4 $5 $6 $7 "$8"
