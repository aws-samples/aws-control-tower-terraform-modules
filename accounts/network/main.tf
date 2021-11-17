// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# Backend configuration to save the state file to the bucket and key defined below.
# The account number is that of the master account.

terraform {
  required_version = "=0.15.3"
  backend "s3" {
    region         = "us-east-1"
    bucket         = "terraform-state-012345678910"
    key            = "tf-iac/network/terraform/state"
    dynamodb_table = "terraform-state-012345678910"
    encrypt        = true
  }
}

# Configure the AWS Provider
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

# These are the common tags that are applied to multiple resources
variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default = {
    environment = "production"
    ou          = "Shared Services"
    region      = "us-east-1"
    owner       = "COMPANY"
  confidentiality = "restricted" }
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

module "config" {
  source = "../../modules/config"
}

################################################################################
# List of Availability Zones
################################################################################

data "aws_availability_zones" "AZ" {
  state = "available"
}

################################################################################
# VPC, Transit Gateway (TGW), and Resource Access Manager
# This section calls the module in the /modules/network folder which creates
# resources such as VPC, subnets, NAT Gateway, TGW, TGW route tables, TGW-VPC attachment,
# and shared the TGW with the "Prod" and "Sandbox" organizational units.
################################################################################

module "Network" {
  source                   = "../../modules/network"
  tags                     = var.tags
  outbound_vpc_cidr        = var.outbound_vpc_cidr
  EgressPublicAZ1_cidr     = var.EgressPublicAZ1_cidr
  EgressPublicAZ2_cidr     = var.EgressPublicAZ2_cidr
  EgressPrivateAZ1_cidr    = var.EgressPrivateAZ1_cidr
  EgressPrivateAZ2_cidr    = var.EgressPrivateAZ2_cidr
  Test_TGW_Attach          = var.Test_TGW_Attach
  Dev_TGW_Attach           = var.Dev_TGW_Attach
  Prod_TGW_Attach          = var.Prod_TGW_Attach
  Sandbox_TGW_Attach       = var.Sandbox_TGW_Attach
}
