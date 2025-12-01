resource "aws_s3_bucket" "s3_bucket" {
    # count = length(var.bucket_names)
    # bucket = var.bucket_names[count.index]
    for_each = var.bucket_name_set
    bucket = each.value
}