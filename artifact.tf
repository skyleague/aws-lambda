# When s3_artifact is provided, fetch the metadata of the object
data "aws_s3_object" "artifact" {
  count = var.s3_artifact != null ? 1 : 0

  bucket     = try(var.s3_artifact.copy_source.bucket, var.s3_artifact.bucket)
  key        = try(var.s3_artifact.copy_source.key, var.s3_artifact.key)
  version_id = try(var.s3_artifact.copy_source.version_id, var.s3_artifact.version_id)

  lifecycle {
    precondition {
      condition     = var.local_artifact == null
      error_message = "Variable s3_artifact should not be provided when local_artifact is provided"
    }
  }
}

resource "aws_s3_object_copy" "artifact_copy" {
  count = try(var.s3_artifact.type, "existing") == "copy" ? 1 : 0

  bucket = var.s3_artifact.bucket
  key    = var.s3_artifact.key

  source = "${var.s3_artifact.copy_source.bucket}/${var.s3_artifact.copy_source.key}"

  tagging_directive = "COPY"
}

locals {
  s3_artifact_prefix = try(
    var.local_artifact.s3_prefix != null ? "${var.local_artifact.s3_prefix}/${var.function_name}" : var.function_name,
    var.function_name
  )
}

# When local_artifact is provided and the type is "dir", zip the contents of the directory
data "archive_file" "artifact_dir" {
  count = var.local_artifact == null ? 0 : var.local_artifact.type == "dir" ? 1 : 0

  type        = "zip"
  source_dir  = var.local_artifact.path
  output_path = "${path.module}/.artifacts/${var.function_name}.zip"
}
# Upload the zipped artifact to S3
resource "aws_s3_object" "artifact_dir" {
  count = var.local_artifact == null ? 0 : var.local_artifact.type == "dir" && var.local_artifact.s3_bucket != null ? 1 : 0

  bucket      = var.local_artifact.s3_bucket
  key         = "${local.s3_artifact_prefix}/handler.zip"
  source      = data.archive_file.artifact_dir[0].output_path
  source_hash = data.archive_file.artifact_dir[0].output_base64sha256

  lifecycle {
    precondition {
      condition     = var.s3_artifact == null
      error_message = "Variable local_artifact should not be provided when s3_artifact is provided"
    }
  }
}

# Upload the pre-existing artifact zip to S3
resource "aws_s3_object" "artifact_zip" {
  count = var.local_artifact == null ? 0 : var.local_artifact.type == "zip" && var.local_artifact.s3_bucket != null ? 1 : 0

  bucket      = var.local_artifact.s3_bucket
  key         = "${local.s3_artifact_prefix}/${basename(var.local_artifact.path)}"
  source      = var.local_artifact.path
  source_hash = filebase64sha256(var.local_artifact.path)

  lifecycle {
    precondition {
      condition     = var.s3_artifact == null
      error_message = "Variable local_artifact should not be provided when s3_artifact is provided"
    }
  }
}

locals {
  # Choose the correct artifact according to the input definition
  artifact      = try(aws_s3_object_copy.artifact_copy[0], data.aws_s3_object.artifact[0], aws_s3_object.artifact_zip[0], aws_s3_object.artifact_dir[0], null)
  artifact_file = var.local_artifact != null && local.artifact == null ? try(data.archive_file.artifact_dir[0].output_path, var.local_artifact.path, null) : null
  source_code_hash = coalesce(
    try(data.archive_file.artifact_dir[0].output_base64sha256, null),
    try(filebase64sha256(local.artifact_file), null),
    try(local.artifact.source_hash, null),
    try(data.aws_s3_object.artifact[0].tags.SourceHash, null),
    try(local.artifact.tags.SourceHash, null),
    try(base64encode(local.artifact.etag), null),
  )
}
