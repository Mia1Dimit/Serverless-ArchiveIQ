locals {
  s3_notifications = {
    for item in flatten([
      for ps_key, s3 in var.s3s : [
        for as_key, notification in s3.notifications : {
          key   = as_key
          value = {
            lambda_function = notification.lambda_function
            bucket = module.s3[ps_key].s3-id
          }
        }
      ]
    ]) : item.key => item.value
  }
}

module "s3" {
  for_each              = var.s3s
  source                = "../modules/s3-bucket"
  bucketname            = each.value["name"]
  rules                 = each.value["rules"]
  blockpublicacls       = each.value["blockpublicacls"]
  blockpublicpolicy     = each.value["blockpublicpolicy"]
  ignorepublicacls      = each.value["ignorepublicacls"]
  restrictpublicbuckets = each.value["restrictpublicbuckets"]
  enable_versioning     = each.value["enable_versioning"]
  specifictags          = each.value["specifictags"]
  name                  = each.value["name"]

  replication_role_arn  = each.value.replication_role != null ? module.aws-iam-role[each.value.replication_role].iam_role_arn : null
  replication_rules     = each.value.replication_rules

  applicationname       = var.applicationname
  applicationid         = var.applicationid
  applicationgroup      = var.applicationgroup
  environment           = each.value["environment"]
}

module "s3-bucket-notification" {
  for_each         = local.s3_notifications
  source           = "../modules/s3-bucket-notification"

  bucket            = each.value.bucket
  lambda_function   = each.value.lambda_function
  
}

module "s3-bucket-policy" {
  for_each    = var.s3_bucket_policies
  source           = "../modules/s3-bucket"
  bucket       = each.value["bucket_name"]
  policy      = file("${path.module}/data/iam_role_policies/${each.value.policy}")
}