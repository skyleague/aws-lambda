variable "function_name" {
  type = string
}
variable "description" {
  type    = string
  default = null
}
variable "local_artifact" {
  description = "Local artifact containing the lambda handler. Valid types are \"dir\" or \"zip\"."
  type = object({
    type      = string
    path      = string
    s3_bucket = string
    s3_prefix = string
  })
  default = null

  validation {
    condition     = var.local_artifact == null || contains(["dir", "zip"], try(var.local_artifact.type, ""))
    error_message = "Invalid \"type\" property for local_artifact, should be \"zip\" or \"dir\"."
  }

  validation {
    condition     = var.local_artifact == null || try(var.local_artifact.type, "") != "zip" || can(regex("\\.zip$", var.local_artifact.path))
    error_message = "Invalid file for type=\"zip\"."
  }

  validation {
    condition     = var.local_artifact == null || try(var.local_artifact.s3_bucket, null) != null || try(var.local_artifact.s3_prefix, null) == null
    error_message = "Invalid \"local_artifact\", \"s3_bucket\" should not be null when \"s3_prefix\" is provided."
  }
}
variable "s3_artifact" {
  description = "Pre-existing artifact stored in S3. Version ID is recommended but optional (provide version_id = null to omit it)."
  type = object({
    bucket     = string
    key        = string
    version_id = string
  })
  default = null
}
variable "runtime" {
  default = "nodejs16.x"
}
variable "handler" {
  default = "index.handler"
}
variable "memory_size" {
  default = 1024
}
variable "timeout" {
  default = 20
}
variable "graviton" {
  description = "Enable AWS Graviton2 processor (better performance, lower cost)"
  type        = bool
  default     = true
}
variable "dead_letter_arn" {
  description = "Dead-letter ARN (SQS or SNS)"
  type        = string
  default     = null

  validation {
    condition     = var.dead_letter_arn == null || can(regex("^arn:aws:(sqs|sns)", var.dead_letter_arn))
    error_message = "Only SQS and SNS are supported for the DLQ."
  }
}
variable "environment" {
  description = "Custom environment variables for the Lambda Function"
  type        = map(string)
  default     = {}
}
variable "ephemeral_storage" {
  description = "Size of the /tmp volume (size is 512 by default on AWS)"
  type        = number
  default     = 512
}
variable "xray_tracing_enabled" {
  description = "Enable XRay Tracing"
  type        = bool
  default     = true
}
variable "file_system_config" {
  description = "EFS file system to mount"
  type = object({
    arn              = string
    local_mount_path = string
    read_only        = bool
  })
  default = null
}
variable "vpc_config" {
  description = "VPC to deploy the Lambda Function into (provide `vpc_config = null` to disable VPC attachment)"
  type = object({
    security_group_ids = list(string)
    subnet_ids         = list(string)
  })
}

variable "log_retention_in_days" {
  description = "Log retention (set to 0 or `null` to never expire)"
  type        = number
  default     = 14
}
variable "log_kms_key_id" {
  description = "Custom KMS key for log encryption"
  type        = string
  default     = null
}

variable "role_name" {
  type    = string
  default = null
}

variable "existing_policy_arns" {
  type    = set(string)
  default = []
}

variable "inline_policies" {
  type    = map(object({ json = string }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
