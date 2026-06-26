resource "aws_s3_bucket" "bucket_s3" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
  tags          = local.merged_tags
}

resource "aws_s3_bucket_public_access_block" "pub_access" {
  bucket = aws_s3_bucket.bucket_s3.id

  block_public_acls       = var.blockpublicacls
  block_public_policy     = var.blockpublicpolicy
  ignore_public_acls      = var.ignorepublicacls
  restrict_public_buckets = var.restrictpublicbuckets
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.bucket_s3.id
  versioning_configuration {
    status = var.enable_versioning
    # mfa_delete removed - not needed for dev/learning environments
    # AWS rejects MalformedXML when mfa_delete is set with versioning = "Disabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "bucket_ownership_controls" {
  bucket = aws_s3_bucket.bucket_s3.id
  rule {
    object_ownership = var.object_ownership
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  count  = length(var.rules) > 0 ? 1 : 0  # Creates only if rules exist
  bucket = aws_s3_bucket.bucket_s3.id
  dynamic "rule" {
    for_each = var.rules
    content {
      id     = rule.value.id
      status = rule.value.status

      dynamic "expiration" {
        for_each = rule.value.expiration != null ? rule.value.expiration : {}
        content {
          days = lookup(expiration.value, "days", null)
          date = lookup(expiration.value, "date", null)
        }
      }

      dynamic "transition" {
        for_each = rule.value.transition != null ? rule.value.transition : {}
        content {
          days          = lookup(transition.value, "days", null)
          date          = lookup(transition.value, "date", null)
          storage_class = lookup(transition.value, "storage_class")
        }
      }

      //filter in AND condition with prefix, object_size_greater_than and object_size_less_than
      dynamic "filter" {
        for_each = rule.value.filters != null ? rule.value.filters : {}
        content {
          and {
            prefix                   = lookup(filter.value, "prefix", null)
            object_size_greater_than = lookup(filter.value, "object_size_greater_than", null)
            object_size_less_than    = lookup(filter.value, "object_size_less_than", null)
          }
        }
      }
    }
  }
}
