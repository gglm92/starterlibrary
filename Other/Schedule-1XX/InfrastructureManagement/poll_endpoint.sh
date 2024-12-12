#################################################################
# Script to Wait Time before provisioning resources
#
# Version: 1.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Licensed Materials - Property of GBM
#
# ©Copyright GBM Corp. 2024.
#
#################################################################

#!/bin/sh

SetParams() {
   SCHEDULE_DATE=$1
   FILE=$2

   # Log params
   printf "Schedule Time: %s\n" $SCHEDULE_TIME
}

WaitTime() {
   # Set params
   SetParams "$1" $2

   printf "Start WaitTime"

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

   status="Finished"

   printf "Final Date: %s\n" $date
   printf $status >$FILE
}

WaitTime "$1" $2
