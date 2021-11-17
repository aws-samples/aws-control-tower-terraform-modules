// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

output "transit_gateway_id" {
  value = aws_ec2_transit_gateway.SharedNetwork_TGW.id
  description = "Transit gateway id to share across accounts"
}
