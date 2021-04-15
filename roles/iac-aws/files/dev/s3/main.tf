locals  {
    all_vars_map = jsondecode(var.all_vars)
    group_vars_map = jsondecode(var.group_vars)
}

resource "aws_s3_bucket" "b" {
  bucket = "dbs-my-tf-dev-bucket"
  acl    = "private"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}