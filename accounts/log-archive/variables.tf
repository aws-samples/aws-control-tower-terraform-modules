// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

variable "automation_role" {}
variable "region" {}
variable "master_account_id" {}

################################################################################
# Variables for guardduty-baseline module.
################################################################################
variable "guardduty_finding_publishing_frequency" {}
