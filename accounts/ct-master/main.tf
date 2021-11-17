// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# Backend configuration to save the state file to the bucket and key defined below.
# The account number is that of the master account.

terraform {
  required_version = "0.15.3"
  backend "s3" {
    region         = "us-east-1"
    bucket         = "terraform-state-123456789012"
    key            = "tf-iac/ct-master/terraform/state"
    dynamodb_table = "terraform-state-123456789012"
    encrypt        = true
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

################################################################################
# Enables Security Hub
################################################################################
resource "aws_securityhub_account" "shaccepter" {
  provider = aws.member
}

################################################################################
# Security Hub Invite accepter
################################################################################

resource "aws_securityhub_invite_accepter" "shaccepter" {
  provider   = aws.member
  depends_on = [aws_securityhub_account.shaccepter]
  master_id  = var.master_account_id
}

################################################################################
# Enables GuardDuty.
################################################################################
resource "aws_guardduty_detector" "gdaccepter" {
  provider                     = aws.member
  enable                       = true
  finding_publishing_frequency = var.guardduty_finding_publishing_frequency
}


################################################################################
# Guard Duty Invite accepter
################################################################################

resource "aws_guardduty_invite_accepter" "gdaccepter" {
  provider          = aws.member
  detector_id       = aws_guardduty_detector.gdaccepter.id
  master_account_id = var.master_account_id
}

################################################################################
# Delegate administrator access for Security Hub
################################################################################
resource "aws_securityhub_organization_admin_account" "SecurityHub_DelegateAdmin" {
  admin_account_id = var.master_account_id
}


################################################################################
# Delegate administrator access for Guard Duty
################################################################################
resource "aws_guardduty_organization_admin_account" "GuardDuty_DelegateAdmin" {
  admin_account_id = var.master_account_id
}

################################################################################
# Encrypting ebs volume by default
################################################################################

resource "aws_ebs_encryption_by_default" "ebs_encryption" {
  enabled = true
}
