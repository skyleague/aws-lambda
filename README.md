# SkyLeague `aws-lambda` - easy AWS Lambda deployments with Terraform

[![tfsec](https://github.com/skyleague/aws-lambda/actions/workflows/tfsec.yml/badge.svg?branch=main)](https://github.com/skyleague/aws-lambda/actions/workflows/tfsec.yml)

This module simplifies the deployment of AWS Lambda Functions using Terraform, as well as simplifying the adoption of the [Principle of Least Privilege](https://aws.amazon.com/blogs/security/techniques-for-writing-least-privilege-iam-policies/). When using this module, there is no need to attach AWS Managed Policies for basic functionality (CloudWatch logging, XRay tracing, VPC access). The Principle of Least Privilege is achieved by letting this module create a separate role for each Lambda Function. This role is granted the bare minimum set of permissions to match the configuration provided to this module. For example, `xray` permissions are automatically granted if (and only if) `xray_tracing_enabled = true`. Similar (dynamic) permissions are provided for other inputs (see [`iam.tf`](./iam.tf) for all dynamic permissions). Additional `existing_policy_arns` and `inline_policies` can be provided to grant the Lambda Function more permissions required by the application code (think of an S3 bucked or DynamoDB table used by your application code).

## Usage

```terraform
module "this" {
  source = "git@github.com:skyleague/aws-lambda.git?ref=v1.0.0

  function_name = "hello-world"
  local_artifact = {
    type      = "dir"
    path      = "${path.module}/.build/hello-world"
    s3_bucket = "my-artifact-bucket"
    s3_prefix = null
  }
}
```

## Options

For a complete reference of all variables, have a look at the descriptions in [`variables.tf`](./variables.tf).

## Outputs

The module outputs the `lambda`, `log_group` and `role` as objects, providing the flexibility to extend the Lambda Function with additional functionality, and without limiting the set of exposed outputs.

## Future additions

This is the initial release of the module, with a very minimal set of standardized functionality. Most other functionality can already be achieved by utilizing the outputs, even the ones mentioned for standardization below. We plan on standardizing more integrations, so feel free to leave suggestions! Candidates include:

- Event triggers with automatic Least Privilige permissions added to the Lambda role
- ... **Your suggestions!**
