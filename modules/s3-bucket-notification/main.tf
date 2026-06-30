resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket      = var.bucket
  eventbridge = var.eventbridge

  dynamic "lambda_function" {
    for_each = var.lambda_functions != null ? var.lambda_functions : []
    content {
      id                  = lookup(lambda_function.value, "id", null)
      lambda_function_arn = lambda_function.value.lambda_function_arn
      events              = lambda_function.value.events

      filter_suffix = try(lambda_function.value.filter_suffix, null)
      filter_prefix = try(lambda_function.value.filter_prefix, null)
    }
  }

  dynamic "queue" {
    for_each = var.queues != null ? var.queues : []
    content {
      id        = lookup(queue.value, "id", null)
      queue_arn = queue.value.queue_arn
      events    = queue.value.events

      filter_suffix = try(queue.value.filter_suffix, null)
      filter_prefix = try(queue.value.filter_prefix, null)
    }
  }

  dynamic "topic" {
    for_each = var.topics != null ? var.topics : []
    content {
      id        = lookup(topic.value, "id", null)
      topic_arn = topic.value.topic_arn
      events    = topic.value.events

      filter_suffix = try(topic.value.filter_suffix, null)
      filter_prefix = try(topic.value.filter_prefix, null)
    }
  }
}