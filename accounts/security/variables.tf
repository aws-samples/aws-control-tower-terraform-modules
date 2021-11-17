// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

variable "region" {}

variable "automation_role" {}

variable "enabled" {
	description = "The boolean flag whether this module is enabled or not. No resources are created when set to false."
}

variable "account_type" {
	description = "The type of the AWS account. The possible values are 'individual', 'master' and 'member'. Specify 'master' and 'member' to set up centralized logging for multiple accounts in AWS Organization. Use 'individual' otherwise."
}

variable "securityhub_enable_cis_standard" {
	description = "Boolean whether CIS standard is enabled."
}

variable "securityhub_enable_aws_foundational_standard" {
	description = "Boolean whether AWS Foundations standard is enabled."
}

variable "guardduty_finding_publishing_frequency" {
	description = "Specifies the frequency of notifications sent for subsequent finding occurrences."
}

variable "master_account_id" {}


variable "target_regions" {
  description = "A list of regions to set up with this module."
  default = [
    "us-east-1"
  ]
}

#Enter member account numbers & email, including the management account

variable "member_accounts" {
  description = "A list of IDs and emails of AWS accounts which associated as member accounts."
  type = list(object({
    account_id = string
    email      = string
  }))

  default = [
   {
    account_id = "123456789012"
    email      = "abc@xyz.com"
   },

	 {
	  account_id = "123456789012"
	  email = "abc@xyz.com"
   },

   {
      account_id = "123456789012"
      email      = "abc@xyz.com"
   },

	 {
      account_id = "123456789012"
      email      = "abc@xyz.com"
   },

	 {
      account_id = "123456789012"
      email      = "abc@xyz.com"
   },

	 {
	   account_id = "123456789012"
	   email = "abc@xyz.com"
   },

	 {
	  account_id = "123456789012"
	  email = "abc@xyz.com"
   },

	 {
	  account_id = "123456789012"
	  email = "abc@xyz.com"
   }
  ]
}
