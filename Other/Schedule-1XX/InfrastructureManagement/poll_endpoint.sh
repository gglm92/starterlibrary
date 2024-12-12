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
   SCHEDULE_DATE=$1

   # Log params
   printf "Schedule Time: %s\n" $SCHEDULE_TIME
}

PollInfrastructureManagement() {
   # Set params
   SetParams "$1"

   printf "Start PollInfrastructureManagement"
   printf "Approval Status: %s\napproved\n"
   result="approved"

   #schedule_ts=$(date -d "$schedule_date" +%s)
   schedule_ts=$(date -d "$SCHEDULE_DATE CST" +%s)

   printf "Schedule Date : %s\n" "$SCHEDULE_DATE"
   printf "Schedule Timestamp: %s\n" "$schedule_ts"

   current_date=$(date +%s)
   printf "Current Date: %s\n" "$current_date"

   diff=$((schedule_ts - current_date))
   while [ "$(date +%s)" -lt "$schedule_ts" ]; do
      date=$(date +"%d/%m/%Y %H:%M")
      sleep $diff
   done

   printf "Final Date: %s\n" $date
   printf $result >$FILE
}

PollInfrastructureManagement "$1"
