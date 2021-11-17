// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

variable "region" {}
variable "automation_role" {}
variable "outbound_vpc_cidr" {}
variable "EgressPublicAZ1_cidr" {}
variable "EgressPublicAZ2_cidr" {}
variable "EgressPrivateAZ1_cidr" {}
variable "EgressPrivateAZ2_cidr" {}

variable "Test_TGW_Attach" {
  description = "TGW Attachment ID of Test VPC, enter N/A if you are running this script for the first time"
  type        = string
}

variable "Dev_TGW_Attach" {
  description = "TGW Attachment ID of Dev VPC, enter N/A if you are running this script for the first time"
  type        = string
}

variable "Prod_TGW_Attach" {
  description = "TGW Attachment ID of Prod VPC, enter N/A if you are running this script for the first time"
  type        = string
}

variable "Sandbox_TGW_Attach" {
  description = "TGW Attachment ID of Sandbox VPC, enter N/A if you are running this script for the first time"
  type        = string
}

variable "master_account_id" {}

################################################################################
# Variables for guardduty-baseline module.
################################################################################
variable "guardduty_finding_publishing_frequency" {}
