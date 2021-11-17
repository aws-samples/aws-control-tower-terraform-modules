// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

region = "us-east-1"
automation_role = "arn:aws:iam::012345678910:role/automation/Terraform"
outbound_vpc_cidr = "10.120.0.0/19"
EgressPublicAZ1_cidr = "10.120.0.0/24"
EgressPublicAZ2_cidr = "10.120.1.0/24"
EgressPrivateAZ1_cidr = "10.120.2.0/24"
EgressPrivateAZ2_cidr = "10.120.3.0/24"


master_account_id = "012345678910"
guardduty_finding_publishing_frequency = "SIX_HOURS"
