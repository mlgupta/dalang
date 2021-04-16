# dalang

Dalang is an Infrastructure as a Code (IaC) automation pipeline. It is built using ansible and terraform. Dalang automates infrastructure deployment in your multi account AWS environment. It can easily be plumbed into any CI/CD pipeline such as AWS Codepipeline, Ansible Tower/AWS, or Github Actions.

## Installation/Build

1. Clone this git repository
```bash
$ git clone https://github.com/dbsentry/dalang.git
```
2. Install required modules using python/pip
```console
$ cd dalang
$ mkdir env
$ python -m venv env
$ . env/bin/activate
(env) $ pip install -r requirements.txt
```
3. Download and install terraform binary. I prefer to copy it under env/bin.

## Usage

1. Start with defining your AWS accounts in the ```inventory.yml``` file.

```
---
all:
  hosts:
    dbsdev:
  children:
    org:
      hosts:
        dbsorg:
    dev:
      hosts:
        dbsdev:
    test:
      hosts:
        dbstest:
    prod:
      hosts:
        dbsprod:
```

We recommend keeping the ```org``` groupname as is. It is also your root AWS account (AWS Organization Account). The groupnames in the inventory files are used to identify with the AWS accounts. New groups can be added or existing groups can be removed. It is important that the above syntax is followed.

2. Modify all.yml group_vars file
```
---
all_vars:
    tfstate_namespace: dbs
    tfstate_stage: org
    tfstate_name: terraform
    tfuser: TerraformUser
    tfrole: TerraformRole
    tfpolicy: TerraformPolicy
    tfuserpolicy: TerraformUserAccess
    org_account_id: 111111111111
    org_account_name: org
    org_user_cred_file: /tmp/tfuser.cred
```
| Name | Description |
|------|-------------|
| tfstate_namespace | |
| tfstate_stage | |
| tfstate_name | |
| tfuser | |
| tfrole | |
| tfpolicy | |
| tfuserpolicy | |
| org_account_id | |
| org_account_name | |
| org_user_cred_file | |
```

3. Modify each AWS environment's group_vars file. Please note that Ansible passes parameters defined in these files to terraform, as per terraform template definition. So, for each terraform stack you define that requires variables, that needs to be defined here.

```
| Name | Description |
|------|-------------|

```


The projects consist of following ansible playbooks:

| Name | Description |
|------|-------------|
| iac-boot.yml |     |
| iac-boot-destroy.yml | |
| iac-plan.yml |     |
| iac-deploy.yml |   |
| iac-destroy.yml |  |


## Copyright

Copyright © 2021 [DBSentry Corp.](https://keyper.dbsentry.com)


## License

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

See [LICENSE](LICENSE) for full details.

```text
Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License.  You may obtain a copy of the License at

  https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied.  See the License for the
specific language governing permissions and limitations
under the License.
```

Some files were sourced from other open source projects and are under their terms and license.


## Trademarks

All other trademarks referenced herein are the property of their respective owners.

## About

This project is maintained and funded by [DBSentry Corp.][website]. Like it? Drop us a [line][feedback]!

I am an independent consultant based in Irving, TX and ❤️  [Open Source Software][dbsentry_github_projects].

We offer paid support on all of our projects.

Check out [our other projects][dbsentry_github_projects], or [hire us][feedback] to help with your cloud strategy and implementation.


[website]: https://keyper.dbsentry.com
[feedback]: http://dbsentry.com/dbsentry/feedback.jsp
[dbsentry_github_projects]: https://github.com/dbsentry