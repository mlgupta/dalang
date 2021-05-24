#############################################################################
# Copyright (c) 2020-2021 DBSentry Corp.  All Rights Reserved.              #
#                                                                           #
# Licensed under the Apache License, Version 2.0 (the "License");           #
# you may not use this file except in compliance with the License.          #
# You may obtain a copy of the License at                                   #
#                                                                           #
#      http://www.apache.org/licenses/LICENSE-2.0                           #
#                                                                           #
# Unless required by applicable law or agreed to in writing, software       #
# distributed under the License is distributed on an "AS IS" BASIS,         #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  #
# See the License for the specific language governing permissions and       #
# limitations under the License.                                            #
#                                                                           #
#############################################################################
locals  {
    all_vars_map = jsondecode(var.all_vars)
    group_vars_map = jsondecode(var.group_vars)
    vpc_vars_map = local.group_vars_map["vpc_vars"]
}

resource "aws_vpc" "vpc" {
  cidr_block = local.vpc_vars_map["vpc_cidr"]
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = merge(local.group_vars_map["default_tags"], tomap({Name="${local.group_vars_map["account_name"]}-vpc"}))
}

resource "aws_internet_gateway" "igw" {
  depends_on = [
    aws_vpc.vpc,
  ]
  vpc_id = aws_vpc.vpc.id
  tags = merge(local.group_vars_map["default_tags"], tomap({Name="${local.group_vars_map["account_name"]}-igw"}))
}

resource "aws_subnet" "private_subnet" {
  depends_on = [
    aws_vpc.vpc,
  ]

  count = length(local.vpc_vars_map["private_subnet_cidr"])

  vpc_id     = aws_vpc.vpc.id
  cidr_block = element(local.vpc_vars_map["private_subnet_cidr"],count.index)
  availability_zone = element(local.vpc_vars_map["azs"],count.index)
  tags = merge(local.group_vars_map["default_tags"], tomap({Name="org-${element(local.vpc_vars_map["azs"],count.index)}-privatesubnet${count.index+1}"}))
}

resource "aws_subnet" "public_subnet" {
  depends_on = [
    aws_vpc.vpc,
  ]

  count = length(local.vpc_vars_map["public_subnet_cidr"])

  vpc_id     = aws_vpc.vpc.id
  cidr_block = element(local.vpc_vars_map["public_subnet_cidr"],count.index)
  availability_zone = element(local.vpc_vars_map["azs"],count.index)
  map_public_ip_on_launch = true

  tags = merge(local.group_vars_map["default_tags"], tomap({Name="org-${element(local.vpc_vars_map["azs"],count.index)}-publicsubnet${count.index+1}"}))
}

resource "aws_route_table" "igw_route_table" {
    depends_on = [
        aws_vpc.vpc,
        aws_internet_gateway.igw,
    ]

    vpc_id = aws_vpc.vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

  tags = merge(local.group_vars_map["default_tags"], tomap({Name="org-route-table"}))
}

resource "aws_route_table_association" "subnet_default_route" {
    depends_on = [
        aws_subnet.public_subnet,
        aws_route_table.igw_route_table,
    ]

    count = length(local.vpc_vars_map["private_subnet_cidr"])

    subnet_id      = aws_subnet.public_subnet[count.index].id
    route_table_id = aws_route_table.igw_route_table.id
}