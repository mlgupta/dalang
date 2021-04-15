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