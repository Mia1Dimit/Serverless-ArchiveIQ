locals {
  s3_notifications = {
    for item in flatten([
      for ps_key, s3 in var.s3s : [
        for as_key, notification in s3.notifications : {
          key         = as_key
          bucket_key  = ps_key
          value = {
            lambda_function = notification.lambda_function
            bucket          = module.s3[ps_key].s3-id
          }
        }
      ]
    ]) : "${item.bucket_key}-${item.key}" => item.value
  }
}

module "s3" {
  for_each              = var.s3s
  source                = "../modules/s3-bucket"
  bucket_name           = each.value["name"]
  rules                 = each.value["rules"]
  blockpublicacls       = each.value["blockpublicacls"]
  blockpublicpolicy     = each.value["blockpublicpolicy"]
  ignorepublicacls      = each.value["ignorepublicacls"]
  restrictpublicbuckets = each.value["restrictpublicbuckets"]
  enable_versioning     = each.value["enable_versioning"]
  specifictags          = each.value["specifictags"]
  name                  = each.value["name"]

  applicationname = var.applicationname
  applicationid   = var.applicationid
  environment     = each.value["environment"]
}

module "s3-bucket-notification" {
  for_each = local.s3_notifications
  source   = "../modules/s3-bucket-notification"

  bucket           = each.value.bucket
  lambda_functions = each.value.lambda_function
}