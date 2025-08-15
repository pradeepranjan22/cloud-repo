# 0-bootstrap Module

## Overview

The `0-bootstrap` module is designed to set up the foundational infrastructure required for managing Terraform state securely and efficiently in AWS. It provisions an S3 bucket for storing Terraform state files, a DynamoDB table for state locking and consistency, and an initial IAM role with administrative permissions to manage Terraform operations. This bootstrap setup ensures that subsequent Terraform deployments can use a remote backend with state locking, enabling collaboration and preventing state corruption.

## Prerequisites

Before using this module, ensure the following:

- **Terraform**: Installed on your local machine. You can download it from [terraform.io](https://www.terraform.io/downloads.html).
- **AWS CLI**: Installed and configured with credentials that have sufficient permissions to create S3 buckets, DynamoDB tables, IAM roles, and related resources.
- **AWS Permissions**: Your AWS user or role must have permissions to:
  - Create and manage S3 buckets and bucket policies.
  - Create DynamoDB tables.
  - Create IAM roles and policies.
  - Manage KMS keys (if applicable).

## Folder Structure

- `main.tf` - Contains the primary Terraform configuration for creating the S3 bucket, DynamoDB table, and IAM role.
- `variables.tf` - Defines the input variables for the module.
- `outputs.tf` - Defines the outputs, including the bucket name, DynamoDB table name, IAM role ARN, and backend configuration.
- `README.md` - This documentation file providing information about the module.

## Usage

To use the `0-bootstrap` module, follow these steps:

1. Initialize Terraform:

   ```
   terraform init
   ```

2. Review the execution plan with your specific variables:

   ```
   terraform plan -var="region=<AWS_REGION>" -var="backend_bucket=<BUCKET_NAME>" -var="dynamodb_table=<TABLE_NAME>" -var="admin_principal_arn=<ARN>"
   ```

3. Apply the configuration to create the bootstrap resources:

   ```
   terraform apply -var="region=<AWS_REGION>" -var="backend_bucket=<BUCKET_NAME>" -var="dynamodb_table=<TABLE_NAME>" -var="admin_principal_arn=<ARN>"
   ```

Replace the placeholders with your desired AWS region, S3 bucket name, DynamoDB table name, and the ARN of the principal (user or role) that will have administrative access to Terraform operations.

## Outputs

After successful deployment, the module provides the following outputs:

- **s3_bucket_name**: The name of the S3 bucket created for storing Terraform state files.
- **dynamodb_table_name**: The name of the DynamoDB table used for state locking.
- **terraform_admin_role_arn**: The ARN of the IAM role with administrative permissions for Terraform.
- **terraform_backend_config**: A map containing the backend configuration parameters (bucket, key, region, and DynamoDB table) to be used in your Terraform backend configuration.

These outputs help you configure your Terraform backend and manage access to your infrastructure state securely.
