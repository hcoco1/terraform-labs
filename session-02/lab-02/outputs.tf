output "bucket_name" {
  value = module.bucket.s3_bucket_id
}

output "dynamodb_table_name" {
  value = module.state_lock.dynamodb_table_id
}