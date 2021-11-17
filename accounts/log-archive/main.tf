// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# Backend configuration to save the state file to the bucket and key defined below.
# The account number is that of the master account.

terraform {
  required_version = "0.15.3"
  backend "s3" {
    region         = "us-east-1"
    bucket         = "terraform-state-123456789012"
    key            = "tf-iac/log-archive/terraform/state"
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

module "config" {
  source = "../../modules/config"
}
