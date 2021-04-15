locals  {
    all_vars_map = jsondecode(var.all_vars)
    group_vars_map = jsondecode(var.group_vars)
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.all_vars_map["org_account_id"]}:root"]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role" "tfrole" {
  name               = local.all_vars_map["tfrole"]
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = merge(local.group_vars_map["default_tags"], map("Name", local.all_vars_map["tfrole"]))
}

resource "aws_iam_policy" "policy" {
  name        = local.all_vars_map["tfpolicy"]
  description = "Terraform Policy"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "iam:*",
          "s3:*",
          "ec2:*",
          "logs:*",
          "kms:*",
          "dynamodb:*"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  })

  tags = merge(local.group_vars_map["default_tags"], map("Name", local.all_vars_map["tfpolicy"]))
}

resource "aws_iam_role_policy_attachment" "tfrole" {
  role       = aws_iam_role.tfrole.name
  policy_arn = aws_iam_policy.policy.arn
}
