locals {
  environment = merge(
    can(regex("^nodejs", var.runtime)) ? {
      AWS_NODEJS_CONNECTION_REUSE_ENABLED = "1"
      NODE_OPTIONS                        = "--enable-source-maps"
    } : {},
    var.environment,
  )
}

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  description   = var.description

  handler     = var.handler
  runtime     = var.runtime
  memory_size = var.memory_size
  timeout     = var.timeout

  architectures = var.graviton ? ["arm64"] : ["x86_64"]

  role = aws_iam_role.this.arn

  dynamic "environment" {
    for_each = length(keys(local.environment)) > 0 ? [local.environment] : []
    content {
      variables = environment.value
    }
  }

  tracing_config {
    mode = var.xray_tracing_enabled ? "Active" : "Passive"
  }

  ephemeral_storage {
    size = var.ephemeral_storage
  }

  s3_bucket         = try(local.artifact.bucket, null)
  s3_key            = try(local.artifact.key, null)
  s3_object_version = try(local.artifact.version_id, null)
  source_code_hash  = local.source_code_hash
  filename          = local.artifact == null ? local.artifact_file : null

  dynamic "dead_letter_config" {
    for_each = var.dead_letter_arn != null ? [var.dead_letter_arn] : []
    content {
      target_arn = dead_letter_config.value
    }
  }

  dynamic "file_system_config" {
    for_each = var.file_system_config != null ? [var.file_system_config] : []
    content {
      arn              = file_system_config.value.arn
      local_mount_path = file_system_config.value.local_mount_path
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      security_group_ids = vpc_config.value.security_group_ids
      subnet_ids         = vpc_config.value.subnet_ids
    }
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.s3_artifact != null || var.local_artifact != null
      error_message = "Either local_artifact or s3_artifact is required."
    }
  }
}


