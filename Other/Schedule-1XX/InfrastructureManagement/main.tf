#################################################################
# Terraform template that will wait time before provisioning resources
#
# Version: 2.4
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Licensed Materials - Property of GBM
#
# ©Copyright GBM Corp. 2020.
#
#################################################################

#########################################################
# Define the variables
#########################################################
variable "schedule_time" {
  default     = ""
  description = "Schedule Time to deploy (YYYY-mm-dd HH:MM)"
}
#########################################################
# Create file to store script output
#########################################################
resource "local_file" "status" {
  content  = ""
  filename = "${path.module}/status"
}

#########################################################
# Wait Time
#########################################################
resource "null_resource" "poll_endpoint" {
  provisioner "local-exec" {
    command = "/bin/bash poll_endpoint.sh \"$SCHEDULE_TIME\" $FILE"
    environment = {
      SCHEDULE_TIME = var.schedule_time
      FILE          = local_file.status.filename
    }
  }
  depends_on = [
    local_file.status
  ]
}

#########################################################
# Data
#########################################################
data "local_file" "status" {
  filename = local_file.status.filename

  depends_on = [
    null_resource.poll_endpoint,
  ]
}

#########################################################
# Output
#########################################################
output "status" {
  value = data.local_file.status.content

  depends_on = [
    null_resource.poll_endpoint,
  ]
}
