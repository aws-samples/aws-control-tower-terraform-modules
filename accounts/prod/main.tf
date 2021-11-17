// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# Backend configuration to save the state file to the bucket and key defined below.
# The account number is that of the master account.

terraform {
  required_version = "=0.15.3"
  backend "s3" {
    region         = "us-east-1"
    bucket         = "terraform-state-012345678910"
    key            = "tf-iac/prod/terraform/state"
    dynamodb_table = "terraform-state-012345678910"
    encrypt        = true
  }
}

# https://www.terraform.io/docs/language/settings/backends/s3.html#multi-account-aws-architecture
variable "workspace_iam_roles" {
  default = {
    base_prod1 = "arn:aws:iam::012345678910:role/automation/Terraform"
    base_prod2 = "arn:aws:iam::012345678910:role/automation/Terraform"
    base_prod3 = "arn:aws:iam::012345678910:role/automation/Terraform"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
  assume_role {
    # Automation Role in Shared Services/Network account
    role_arn     = var.workspace_iam_roles[terraform.workspace]
    external_id = "terraform"
    session_name = "terraform"
  }
}

provider "aws" {
    alias = "member"
    region = var.region
    assume_role {
    # Automation Role in Shared Services/Network account
    role_arn     = var.workspace_iam_roles[terraform.workspace]
    external_id = "terraform"
    session_name = "terraform"
  }
}

# Get transit gateway id from state file

# data "terraform_remote_state" "SharedNetwork_TGW" {
#   backend = "s3"
#   config = {
#     region = "us-east-1"
#     bucket = "terraform-state-583682484031"
#     key    = "tf-iac/network/terraform/state"
#   }
# }

module "config" {
  source = "../../modules/config"
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
# Enables GuardDuty
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
# VPC, Subnets, and Transit Gateway (TGW) attachment
# This section calls the module in the /modules/prod folder which creates
# resources such as VPC, subnets, route tables, associations and TGW-VPC attachment
################################################################################

module "Prod" {
  source             = "../../modules/prod"
  region             = var.region
  cidr_block         = var.cidr_block
  az                 = var.az
  transit_gateway_id = var.transit_gateway_id
# transit_gateway_id = data.terraform_remote_state.SharedNetwork_TGW.outputs.transit_gateway_id
}
