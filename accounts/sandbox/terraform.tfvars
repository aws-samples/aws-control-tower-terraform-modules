// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

region = "us-east-1"
automation_role = "arn:aws:iam::012345678910:role/automation/Terraform"

cidr_block = [{
      upn-vpc = "10.120.64.0/19"
      app_subnet_1      = "10.120.64.0/23"
      app_subnet_2      = "10.120.66.0/23"
      app_subnet_3      = "10.120.68.0/23"
      db_subnet_1       = "10.120.70.0/23"
      db_subnet_2       = "10.120.72.0/23"
      db_subnet_3       = "10.120.74.0/23"
}]

az = [{
      az1 = "us-east-1a"
      az2 = "us-east-1b"
      az3 = "us-east-1c"
}]

master_account_id = "012345678910"
guardduty_finding_publishing_frequency = "SIX_HOURS"
