// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

variable "region" {
  default = "us-east-1"
}

variable "az" {
  type = list(object({
    az1 = string
    az2 = string
    az3 = string
  }))
  default = [
    {
      az1 = "us-east-1a"
      az2 = "us-east-1b"
      az3 = "us-east-1c"
    }
  ]
}

# CIDR blocks for Prod accounts

variable "cidr_block" {
  type = list(object({
    prod_vpc = string
    app_subnet_1      = string
    app_subnet_2      = string
    app_subnet_3      = string
    db_subnet_1       = string
    db_subnet_2       = string
    db_subnet_3       = string
  }))
}

variable "master_account_id" {
  description = "The ID of the master AWS account to which the current AWS account is associated. Required if 'account_type' is 'member'."
  default     = "012345678910"
}

variable "transit_gateway_id" {
  description = "This ID is generated during the deployment of the Shared Transit Gateway in the Network Account"
}

################################################################################
# Variables for guardduty-baseline module.
################################################################################
variable "guardduty_finding_publishing_frequency" {
  description = "Specifies the frequency of notifications sent for subsequent finding occurrences."
  default     = "SIX_HOURS"
}
