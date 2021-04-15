locals  {
    all_vars_map = jsondecode(var.all_vars)
    group_vars_map = jsondecode(var.group_vars)
}

resource "aws_iam_user" "tfuser" {
  name               = local.all_vars_map["tfuser"]
  force_destroy      = true

  tags = merge(local.group_vars_map["default_tags"], map("Name", local.all_vars_map["tfuser"]))
}

resource "aws_iam_access_key" "access_key" {
  user               = aws_iam_user.tfuser.name
}

resource "aws_iam_user_policy" "tfuserpolicy" {
  name        = local.all_vars_map["tfuserpolicy"]
  user = aws_iam_user.tfuser.name

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Resource": "arn:aws:iam::*:role/${local.all_vars_map["tfrole"]}"
      }
    ]
  })
}

resource "local_file" "tfuser_creds" {
    content     = "AWS_ACCESS_KEY_ID: ${aws_iam_access_key.access_key.id}, AWS_SECRET_ACCESS_KEY: ${aws_iam_access_key.access_key.secret}"
    filename = local.all_vars_map["org_user_cred_file"]
}