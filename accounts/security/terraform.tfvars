// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

region = "us-east-1"

#Security Account ID
master_account_id = "123456789012"

#Enter the security account ID
automation_role = "arn:aws:iam::123456789012:role/automation/Terraform"

#The boolean flag whether this module is enabled or not. No resources are created when set to false.
enabled = true

# The type of the AWS account. The possible values are 'individual', 'master' and 'member'.
# Specify 'master' and 'member' to set up centralized logging for multiple accounts in AWS Organization.
# Use individual' otherwise.
account_type = "individual"

# Boolean whether CIS standard is enabled.
securityhub_enable_cis_standard = true

# Boolean whether AWS Foundations standard is enabled.
securityhub_enable_aws_foundational_standard = true

# Specifies the frequency of notifications sent for subsequent finding occurrences.
guardduty_finding_publishing_frequency = "SIX_HOURS"
