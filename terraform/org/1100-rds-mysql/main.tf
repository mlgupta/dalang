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
    rds_mysql_vars_map = local.group_vars_map["rds_mysql_vars"]
}

#############################################################################
# Import Data for required previously created resources
#############################################################################
data "aws_vpc" "vpc" {
  count = local.rds_mysql_vars_map["rds_vpc_exist"] ? 1 : 0

  filter {
    name   = "tag:Name"
    values = ["${local.group_vars_map["account_name"]}-vpc"]
  }
}

data "aws_subnet_ids" "private" {
  count = local.rds_mysql_vars_map["rds_vpc_exist"] ? 1 : 0
  vpc_id = data.aws_vpc.vpc[0].id
  filter {
    name   = "cidr-block"
    values = local.vpc_vars_map["private_subnet_cidr"]
  }
}

################################################################################
# Security Group
################################################################################
module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 3"

  name        = lower("${local.group_vars_map["account_name"]}-rds-mysql")
  description = "MySQL security group"
  vpc_id      = lookup(data.aws_vpc.vpc,"id","")

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "MySQL access from within VPC"
      cidr_blocks = lookup(data.aws_vpc.vpc,"cidr_block","")
    },
  ]

  tags = merge(local.group_vars_map["default_tags"], map("Name", lower("${local.group_vars_map["account_name"]}-rds-mysql")))
}

################################################################################
# RDS MySQL
################################################################################
module "db" {
  source = "terraform-aws-modules/rds/aws"
  version = "~> 2.0"

  identifier = lower("${local.group_vars_map["account_name"]}-rds-mysql")

  engine               = "mysql"
  engine_version       = "8.0.20"
  family               = "mysql8.0" # DB parameter group
  major_engine_version = "8.0"      # DB option group
  instance_class       = "db.t3.micro"

  allocated_storage     = 5
  max_allocated_storage = 50
  storage_encrypted     = false

  name     = local.rds_mysql_vars_map["rds_db_name"]
  username = local.rds_mysql_vars_map["rds_db_username"]
  password = "1qazxsw2"
  port     = 3306

  multi_az               = false
  subnet_ids             = lookup(data.aws_subnet_ids.private,"ids","")
  vpc_security_group_ids = [module.security_group.this_security_group_id]

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["general"]

  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  create_monitoring_role                = true
  monitoring_interval                   = 60

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    }
  ]

  tags = merge(local.group_vars_map["default_tags"], map("Name", lower("${local.group_vars_map["account_name"]}-rds-mysql")))
}
