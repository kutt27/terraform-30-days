variable "bucket_names" {
  type = list(string)
  default = [ "amal-s3-bucket-terraform30days-10", "amal-s3-bucket-terraform30days-20" ]
}

variable "bucket_name_set" {
  type = set(string)
  default = ["amal-s3-bucket-terraform30days-10", "amal-s3-bucket-terraform30days-20"]
}