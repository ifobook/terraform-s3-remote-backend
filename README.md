# Terraform S3 Remote Backend Setup

## Project Overview

This project demonstrates modular AWS infrastructure provisioning
with Terraform, secure S3 remote state management, native state
locking, IAM access control, and environment separation.

## Technologies

- Terraform
- AWS VPC
- Amazon S3
- AWS IAM
- AWS CLI
- Git and GitHub

## Architecture

The infrastructure consists of three independent Terraform root
configurations:

- Bootstrap: provisions the S3 remote state bucket.
- Dev: provisions the development network.
- Prod: provisions the production network.

Both environments reuse the same VPC module but maintain independent
configuration values and remote state files.

| Component | Development | Production |
|---|---|---|
| VPC CIDR | 10.0.0.0/16 | 10.1.0.0/16 |
| Public subnets | 2 | 2 |
| Private subnets | 2 | 2 |
| Availability zones | 2 | 2 |
| Internet gateways | 1 | 1 |
| Route tables | 2 | 2 |
| State key | dev/terraform.tfstate | prod/terraform.tfstate |

## Project Structure

    terraform-s3-remote-backend/
    ├── bootstrap/
    ├── modules/
    │   ├── s3/
    │   └── vpc/
    ├── environments/
    │   ├── dev/
    │   └── prod/
    ├── policies/
    ├── screenshots/
    ├── .gitignore
    └── README.md

## Reusable Modules

### S3 Module

The S3 module provisions a secure remote state bucket with:

- Bucket versioning
- AES256 server-side encryption
- Public access blocking
- Bucket owner enforced object ownership
- A bucket policy denying insecure HTTP transport

### VPC Module

The VPC module provisions:

- One VPC
- Two public subnets
- Two private subnets
- One internet gateway
- Public and private route tables
- Subnet route table associations

Private subnets are intentionally isolated. NAT gateways and EC2
instances are excluded to minimize infrastructure costs.

## Prerequisites

- Terraform 1.10 or later
- AWS CLI
- An authenticated AWS IAM identity
- Appropriate VPC and S3 permissions
- Git

## AWS Authentication

    aws login --profile devops-admin
    export AWS_PROFILE=devops-admin
    export AWS_REGION=eu-west-1
    aws sts get-caller-identity

## Bootstrap the Remote Backend

Copy the example variables file:

    cp bootstrap/terraform.tfvars.example bootstrap/terraform.tfvars

Replace the bucket name with a globally unique S3 bucket name.

    terraform -chdir=bootstrap init
    terraform -chdir=bootstrap validate
    terraform -chdir=bootstrap plan -out=bootstrap.tfplan
    terraform -chdir=bootstrap apply bootstrap.tfplan

The bootstrap configuration uses local state to avoid a circular
dependency when creating the remote backend.

## Configure Environment Variables

    cp environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars
    cp environments/prod/terraform.tfvars.example environments/prod/terraform.tfvars

    cp environments/dev/backend.tfbackend.example environments/dev/backend.tfbackend
    cp environments/prod/backend.tfbackend.example environments/prod/backend.tfbackend

Replace the placeholder bucket name in both backend configuration files
with the bucket created during bootstrap.

## Local-to-Remote State Migration

During the learning exercise, the Dev environment was initially
deployed using local state.

After successful deployment, the S3 backend configuration was added
and the existing state was migrated using:

    terraform -chdir=environments/dev init -migrate-state -backend-config=backend.tfbackend

The migration was confirmed interactively.

The migrated state was verified in Amazon S3, and a subsequent
Terraform plan confirmed that no infrastructure changes were needed.

The final repository already contains the S3 backend blocks.
For a fresh deployment, initialize the remote backend directly
instead of repeating the historical migration.

## Deploy Dev

    terraform -chdir=environments/dev init -backend-config=backend.tfbackend
    terraform -chdir=environments/dev validate
    terraform -chdir=environments/dev plan -out=dev.tfplan
    terraform -chdir=environments/dev apply dev.tfplan

## Deploy Prod

    terraform -chdir=environments/prod init -backend-config=backend.tfbackend
    terraform -chdir=environments/prod validate
    terraform -chdir=environments/prod plan -out=prod.tfplan
    terraform -chdir=environments/prod apply prod.tfplan

## Input Variables

| Variable | Description |
|---|---|
| aws_region | AWS deployment region |
| bucket_name | Globally unique S3 state bucket name |
| environment | Deployment environment name |
| vpc_cidr | VPC network address range |
| public_subnets | Public subnet CIDRs and availability zones |
| private_subnets | Private subnet CIDRs and availability zones |

## Outputs

| Output | Description |
|---|---|
| state_bucket_name | Remote state bucket name |
| state_bucket_arn | Remote state bucket ARN |
| vpc_id | Provisioned VPC ID |
| public_subnet_ids | Public subnet IDs |
| private_subnet_ids | Private subnet IDs |
| internet_gateway_id | Internet gateway ID |

## Remote State Security

The S3 backend uses native Terraform state locking through
use_lockfile = true.

The custom IAM policy is located at:

    policies/terraform-state-access.json

It grants scoped permissions to list the relevant bucket prefixes,
read and update Terraform state, and create or remove lock files.

The policy was created and attached through the AWS IAM Console.
Update its bucket ARNs when reproducing this project with another bucket.

Temporary AmazonS3FullAccess permissions were removed during testing.

Both Dev and Prod Terraform plans completed successfully, while an
attempt to list all S3 buckets returned AccessDenied.

## Verification Results

- All three Terraform configurations validated successfully.
- S3 bucket versioning and encryption were configured.
- Dev and Prod infrastructure were deployed independently.
- Dev local state was successfully migrated to S3.
- Separate Dev and Prod remote state files were verified.
- Both environments returned no changes during verification.
- State locking and restricted IAM access were demonstrated.

## Screenshot Evidence

The screenshots directory contains evidence of:

1. S3 bootstrap deployment.
2. S3 bucket creation.
3. S3 bucket versioning.
4. Dev Terraform deployment.
5. Dev local state.
6. Dev VPC in AWS.
7. Remote backend migration.
8. Remote state verification.
9. Dev state object in S3.
10. Prod Terraform deployment.
11. Dev and Prod VPC separation.
12. S3 environment separation.
13. Restricted IAM policy.
14. Restricted access verification.

## Security Practices

- No root credentials are used for Terraform deployment.
- Terraform state files are excluded from Git.
- Local backend configuration and variable files are excluded from Git.
- Provider dependency lock files are committed.
- Public S3 access is blocked.
- Remote state is encrypted and versioned.
- Separate state keys are used for each environment.

## Cleanup

Destroy Dev and Prod infrastructure before deleting the S3 backend.

    terraform -chdir=environments/prod destroy
    terraform -chdir=environments/dev destroy

The versioned S3 bucket must be emptied of all object versions and
delete markers before destroying the bootstrap configuration.

Temporary IAM permissions and the custom state-access policy should
also be removed after the exercise.

## Conclusion

This project demonstrates reusable infrastructure modules,
Infrastructure as Code, secure remote state management, environment
isolation, state locking, and IAM access control using Terraform
and AWS.
