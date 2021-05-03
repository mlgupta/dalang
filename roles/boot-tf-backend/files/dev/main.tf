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
    backend_vars_map = jsondecode(var.backend_vars)
}

module "terraform_state_backend" {
   source = "cloudposse/tfstate-backend/aws"
   version     = "0.33.0"
   
   namespace  = local.all_vars_map["tfstate_namespace"]
   stage      = local.group_vars_map["account_name"]
   name       = local.all_vars_map["tfstate_name"]
   attributes = ["state"]

   terraform_backend_config_file_path = local.backend_vars_map["terraform_backend_config_file_path"]
   terraform_backend_config_file_name = "backend.tf"
   force_destroy                      = local.backend_vars_map["force_destroy"]

   s3_replication_enabled = false
   s3_replica_bucket_arn  = ""

   tags = local.group_vars_map["default_tags"]
}