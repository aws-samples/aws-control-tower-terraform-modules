// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# Backend configuration to save the state file to the bucket and key defined below.
# The account number is that of the master account.

terraform {
  required_version = "0.15.3"
  backend "s3" {
    region         = "us-east-1"
    bucket         = "terraform-state-123456789012"
    key            = "tf-iac/security/terraform/state"
    dynamodb_table = "terraform-state-123456789012"
    encrypt = true
    }
}

################################################################################
# Configure the AWS Provider
################################################################################
provider "aws" {
  region = var.region
  assume_role {
    # Automation Role in Shared Services/Network account
    role_arn = var.automation_role
    external_id = "terraform"
    session_name = "terraform"
  }
}

provider "aws" {
    alias = "member"
    region = var.region
    assume_role {
    # Automation Role in Shared Services/Network account
    role_arn = var.automation_role
    external_id = "terraform"
    session_name = "terraform"
  }
}

locals {
  is_individual_account = var.account_type == "individual"
  is_master_account     = var.account_type == "master"
  is_member_account     = var.account_type == "member"
  is_cloudtrail_enabled = local.is_individual_account || local.is_master_account
  all_member_accounts   = var.member_accounts

################################################################################
# Declaring SecurityHub variables
################################################################################
  enabled                          = contains(var.target_regions, "us-east-1")
  enable_cis_standard              = var.securityhub_enable_cis_standard
  enable_aws_foundational_standard = var.securityhub_enable_aws_foundational_standard


################################################################################
# Declaring Guard Duty variables
################################################################################
  finding_publishing_frequency 	= var.guardduty_finding_publishing_frequency
}


################################################################################
# Enables GuardDuty.
################################################################################
resource "aws_guardduty_detector" "main" {
  count = var.enabled ? 1 : 0
  enable                       = true
  finding_publishing_frequency = var.guardduty_finding_publishing_frequency
}

################################################################################
# Add member accounts
################################################################################
resource "aws_guardduty_member" "members" {
  count = var.enabled ? length(var.member_accounts) : 0

  detector_id                = aws_guardduty_detector.main[0].id
  invite                     = true
  account_id                 = var.member_accounts[count.index].account_id
  email                      = var.member_accounts[count.index].email
}


################################################################################
# Enables SecurityHub
################################################################################
resource "aws_securityhub_account" "main" {
  count = var.enabled ? 1 : 0
}


################################################################################
# Add member accounts
################################################################################
resource "aws_securityhub_member" "members" {
  count = var.enabled ? length(var.member_accounts) : 0

  depends_on = [aws_securityhub_account.main]
  account_id = var.member_accounts[count.index].account_id
  email      = var.member_accounts[count.index].email
  invite     = true
}

################################################################################
# Subscribe CIS benchmark
################################################################################
resource "aws_securityhub_standards_subscription" "cis" {
  count = var.enabled && var.securityhub_enable_cis_standard ? 1 : 0

  standards_arn = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"

  depends_on = [aws_securityhub_account.main]
}

################################################################################
# Subscribe AWS foundational security best practices standard
################################################################################
resource "aws_securityhub_standards_subscription" "aws_foundational" {
  count = var.enabled && var.securityhub_enable_aws_foundational_standard ? 1 : 0

  standards_arn = "arn:aws:securityhub:${var.region}::standards/aws-foundational-security-best-practices/v/1.0.0"

  depends_on = [aws_securityhub_account.main]
}

################################################################################
# Encrypt ebs volume
################################################################################

resource "aws_ebs_encryption_by_default" "ebs_encryption" {
  enabled = true
}
