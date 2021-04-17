# dalang

Dalang is a collection of Ansible Playbooks developed for Infrastructure as a Code (IaC) automation. It automates infrastructure deployment in your multi-account AWS environment. Dalang can easily be added to any CI/CD pipeline such as AWS Codepipeline, Ansible Tower/AWS, or Github Actions.

## Architecture

![Dalang Architecture](https://keyper.dbsentry.com/media/dalang.png)  


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

The projects come with the following Ansible playbooks:

| Name | Description |
|------|-------------|
| iac-boot.yml | Creates S3 backend, users, and roles used for the AWS resource deployment. Although this playbook can run against all environments at once, we recommend running it one by one against each AWS environment using ```ansible-playbook -l``` flag. |
| iac-boot-destroy.yml | Deletes roles and S3 backend for the target AWS account. Before running this playbook, ensure that all the terraform resources created and stored on this backend were already deleted. Otherwise, they would remain in the AWS account. |
| iac-plan.yml | Runs against each terraform stack (defined under ```terraform/\<env\>/\<stack\>```) and generates terraform plan on stdout. If multiple stacks are specified using ```--tags```, they are sorted. |
| iac-deploy.yml | Runs against each terraform stack (defined under ```terraform/\<env\>/\<stack\>```) and creates AWS resources. If multiple stacks are specified using ```--tags``` then they are sorted and then applied individually. To keep the blast radius small, we recommend specifying the stack using ```--tags```. |
| iac-destroy.yml | Runs ```terraform destroy``` against each stack specified using ```--tags``` |


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

We recommend keeping the ```org``` group name as is. It is also your root AWS account (AWS Organization Account). The group names in the inventory files identify AWS accounts. New groups can be added or existing groups can be removed from the file as per your need. The above syntax must be followed.

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
| tfstate_namespace | S3 backend gets created in a form \<tfstate_namespace\>-\<tfstate_stage\>-\<tfstate_name\>-state. Typically, this can be set to the abbreviation for your organization.|
| tfstate_stage | Environment AWS account corresponds to. for e.g. dev, test, etc|
| tfstate_name | Set it to "terraform"|
| tfuser | IAM User in the ```org``` account used by ```iac-deploy.yml``` to authenticate against AWS, and then perform assume role for the target AWS environment.|
| tfrole | Role assumed by ```iac-deploy.yml``` playbook to deploy resources in the target AWS account. |
| tfpolicy | Name of the AWS IAM policy created in the target AWS account. This policy is attached to the tfrole. |
| tfuserpolicy | Name of the AWS IAM policy in the "org" account. It has minimal permission that allows this user to perform assume role against the target AWS environment. |
| org_account_id | AWS account ID for the "org" account|
| org_account_name | AWS account name for the "org" account. We recommend this to be set to "org" |
| org_user_cred_file | Credential file for tfuser created by ```iac-boot.yml```. Content of this file must be entered into ansible-vault file ```aws-deploy-secrets.yml```. This file has the same syntax as ```aws-secrets.yml```.|


3. Modify each AWS environment's group_vars file. Please note that Ansible passes parameters defined in these files to terraform, as per terraform template definition. So, variables for each Terraform stack need to be defined here.

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
| account_id | AWS account ID for the target AWS account. |
| account_name | AWS account name. for e.g. org, dev, test, prod, etc |
| default_tags | Default tags that needs to be applied to each AWS resource that is created in this AWS account. |

Above ```vpc_vars``` is defined as dict. Ansible passes these to terraform stack ```0100-vpc```.

4. Create an ansible-vault file ```aws-secrets.yml``` place its password in ```.vault_pass``` file. This file is used by the dalang boot process that sets up terraform S3 backend for each AWS account and creates a ```TerraformUser``` user in ```org``` account and ```TerraformRole``` in each AWS account. The accounts defined in this file have elevated privileges that allow them to create users/roles and assign and define policies for the roles.

The file has the following structure:

```
org_aws_access_key_id: XXXXXXXXXXXXX
org_aws_secret_access_key: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
org_aws_default_region: us-east-1
dev_aws_access_key_id: XXXXXXXXXXXXX
dev_aws_secret_access_key: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
dev_aws_default_region: us-east-1
test_aws_access_key_id: XXXXXXXXXXXXX
test_aws_secret_access_key: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
test_aws_default_region: us-east-1
prod_aws_access_key_id: XXXXXXXXXXXXX
prod_aws_secret_access_key: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
prod_aws_default_region: us-east-1
```

| Name | Description |
|------|-------------|
| \<env\>_aws_access_key_id | AWS Access Key ID|
| \<env\>_aws_secret_access_key | AWS Secret Access Key |
| \<env\>_aws_default_region | AWS Default Region |

5.  Create an ansible-vault file ```aws-deploy-secrets.yml``` using the password in ```.vault_pass``` file. Add credentials for ```TerraformUser``` created by ```iac-boot.yml``` to this file. This file is used by ```iac-deploy.yml```, ```iac-plan.yml```, and ```iac-destroy.yml``` to authenticate against AWS org account and then do a assume role against target account to manage resources. 

The file has the following structure:

```
org_aws_access_key_id: AKIAY5BD5CISQBCDJC6G
org_aws_secret_access_key: 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
org_aws_default_region: us-east-1
```

6. For each AWS account, create a folder under ```roles/boot-tf-backend/files```. The name of the folder must be the same as what is defined in the ```inventory.yml``` file.

7. Copy ```main.tf``` and ```variables.tf``` file from ```org``` folder to this new folder.

```console
$ cd roles/boot-tf-backend/files
$ mkdir prod
$ cd prod
$ cp ../org/main.tf .
$ cp ../org/variables.tf .
```

8. Run ansible-playbook ```iac-boot.yml``` for each AWS account. e.g.

```console
$ ansible-playbook -l org iam-boot.yml
$ ansible-playbook -l dev iam-boot.yml
```

Above playbook execution does the following:
- Authenticates against AWS account specified using ```-l```
- Creates a encrypted terraform S3 backend and dynamodb table using fantastic terraform module [cloudposse/terraform-aws-tfstate-backend](https://github.com/cloudposse/terraform-aws-tfstate-backend)
- It creates a user ```TerraformUser``` for the ```org``` account. This account has access only to terraform S3 backend, and it can assume a role against the target account. Credential for this user is generated by ```iac-boot.yml``` in ```org_user_cred_file``` as defined in all.yml.
- Creates a role ```TerraformRole```. Terraform uses this role to deploy infrastructure. This role needs to have appropriate permission to create AWS resources. Default permissions defined are minimal, so the ```main.tf``` file under ```boot-tf-role``` role must be modified for each environment and ```iac-boot.yml``` playbook run so that appropriate permission is granted to ```TerraformRole```.

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