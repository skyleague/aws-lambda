data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  path        = "/lambda/"
  name_prefix = var.function_name

  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "this" {
  statement {
    effect = "Allow"
    actions = [
      # We explicitly exclude the CreateLogGroup action
      # The log group is created by Terraform
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    # This only allows creating log streams and putting log events in this specific log group
    #tfsec:ignore:aws-iam-no-policy-wildcards
    resources = ["${aws_cloudwatch_log_group.this.arn}:*", ]
  }

  dynamic "statement" {
    for_each = var.xray_tracing_enabled ? [true] : []
    content {
      effect = "Allow"
      actions = [
        "xray:PutTraceSegments",
        "xray:PutTelemetryRecords",
      ]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.vpc_config != null ? [true] : []
    content {
      effect = "Allow"
      actions = [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:AssignPrivateIpAddresses",
        "ec2:UnassignPrivateIpAddresses",
      ]

      # This policy is a narrowed-down version of the AWS-Managed policy.
      # https://us-east-1.console.aws.amazon.com/iam/home#/policies/arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole$jsonEditor
      # 
      # It cannot be more narrow than this, otherwise AWS Lambda won't be able to
      # associate the Lambda Function to the VPC.
      #tfsec:ignore:aws-iam-no-policy-wildcards
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.dead_letter_arn != null ? [var.dead_letter_arn] : []
    content {
      effect    = "Allow"
      actions   = can(regex("^arn:aws:sqs", statement.value)) ? ["sqs:SendMessage"] : can(regex("^arn:aws:sns", statement.value)) ? ["sns:Publish"] : []
      resources = [statement.value]
    }
  }

  dynamic "statement" {
    for_each = var.file_system_config != null ? [var.file_system_config] : []
    content {
      effect = "Allow"
      actions = statement.value.read_only == false ? [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientWrite",
      ] : ["elasticfilesystem:ClientMount"]
      resources = [statement.value.arn]
    }
  }
}

resource "aws_iam_role_policy" "this" {
  role        = aws_iam_role.this.id
  name_prefix = "base"
  policy      = data.aws_iam_policy_document.this.json
}

resource "aws_iam_role_policy" "inline_policies" {
  for_each = var.inline_policies

  role        = aws_iam_role.this.id
  name_prefix = each.key
  policy      = each.value.json
}

resource "aws_iam_role_policy_attachment" "existing_policies" {
  for_each = var.existing_policy_arns

  role       = aws_iam_role.this.id
  policy_arn = each.value
}
