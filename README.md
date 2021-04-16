# dalang

Dalang is an Infrastructure as a Code (IaC) automation pipeline. It is built using ansible and terraform. Dalang automates infrastructure deployment in your multi account AWS environment. It can easily be plumbed into any CI/CD pipeline such as AWS Codepipeline, Ansible Tower/AWS, or Github Actions.

## Installation/Build

1. Clone this git repository
```console
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

The projects comes with following ansible playbooks:

| Name | Description |
|------|-------------|
| iac-boot.yml | This playbook creates S3 backend, users, and roles that is used for the AWS resource deployment. Although this playbook can run against all environment, we recommend running it one by one against each AWS environment using ```ansible-playbook -l``` flag. |
| iac-boot-destroy.yml | This playbook deletes roles and S3 backend for the target AWS account. Before running this playbook, make sure that all the terraform resources created and stored on this backend are deleted. Otherwise, they would remain in AWS dangling. |
| iac-plan.yml | This playbook runs against each terraform stack (defined under ```terraform/\<env\>/\<stack\>```) and generates terraform plan on stdout. If multiple stacks are specified using ```--tags``` then they are sorted as list and then. |
| iac-deploy.yml | This playbook runs against each terraform stack (defined under ```terraform/\<env\>/\<stack\>```) and creates AWS resources. If multiple stacks are specified using ```--tags``` then they are sorted as list and then applied individually one-by-one. In order to keep the blast radius small, we recommend specifying stack name to be applied using ```--tags```. |
| iac-destroy.yml | This playbook runs ```terraform destroy``` against each stack specified using ```--tags``` |


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


3. Modify each AWS environment's group_vars file. Please note that Ansible passes parameters defined in these files to terraform, as per terraform template definition. So, for each terraform stack you define that requires variables, that needs to be defined here.

```
group_vars:
    account_id: 111111111111
    account_name: org
    default_tags:
        owner: ""
        userid: ""
        company: ""
        organization: ""
####################################################
    vpc_vars:
        azs:
            - us-east-1a
            - us-east-1b
            - us-east-1c
        vpc_cidr: "10.10.0.0/16"
        public_subnet_cidr:
            - 10.10.1.0/24
            - 10.10.4.0/24
            - 10.10.7.0/24
        private_subnet_cidr:
            - 10.10.3.0/24
            - 10.10.6.0/24
            - 10.10.9.0/24
####################################################
```

| Name | Description |
|------|-------------|
| account_id | |
| account_name | |
| default_tags | |

Above ```vpc_vars``` is defined as dict. Ansible passes these to terraform stack ```0100-vpc```.

4. Create a ansible-vault file ```aws-secrets.yml``` place its password in ```.vault_pass``` file. This file is used by dalang boot process that sets up terraform S3 backend for each AWS account, and creats a ```TerraformUser``` user in ```org``` account and ```TerraformRole``` in each AWS account. The accounts defined in this file have elevated privilges that allows them to create users/roles and assign and define policies for the roles.

The file has following structure:

```
org_aws_access_key_id: AKIAY5EQ5CISQBCDJC6K
org_aws_secret_access_key: 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
org_aws_default_region: us-east-1
dev_aws_access_key_id: AKIAY5EQ5CISQBCDJC6K
dev_aws_secret_access_key: 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
dev_aws_default_region: us-east-1
test_aws_access_key_id: AKIAY5EQ5CISQBCDJC6K
test_aws_secret_access_key: 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
test_aws_default_region: us-east-1
prod_aws_access_key_id: AKIAY5EQ5CISQBCDJC6K
prod_aws_secret_access_key: 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
prod_aws_default_region: us-east-1
```

| Name | Description |
|------|-------------|
| \<env\>_aws_access_key_id | |
| \<env\>_aws_secret_access_key | |
| \<env\>_aws_default_region | |

5. Run ansible playbook ```iac-boot.yml``` for each AWS account. for e.g.

```console
$ ansible-playbook -l org iam-boot.yml
$ ansible-playbook -l dev iam-boot.yml
```

Above playbook execution does the following:
- Authenticates against the specified AWS account
- Creates a terraform S3 backend along with dynamodb table
- For the ```org``` account it creates a user ```TerraformUser```. This account has access only to terraform S3 backend, and it has ability to assume role against target account. Credentials for this users are saved in ```org_user_cred_file``` as defined in all.yml group_vars file.
- Creates a role ```TerraformRole```. Terraform uses this role to deploy infrastructure. This role needs to have appropriate permission to create AWS resources.

6. Create a ansible-vault file ```aws-deploysecrets.yml```. This file is used by terraform deploy playbooks to deploy AWS infrastructure.

The file has following structure:

```
org_aws_access_key_id: AKIAY5BD5CISQBCDJC6G
org_aws_secret_access_key: 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
org_aws_default_region: us-east-1
```


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