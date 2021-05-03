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