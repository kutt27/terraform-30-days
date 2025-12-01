locals {
    # bucket_name = "${var.learner}-bucket-terraform30days-${var.environment}-${var.region}"
    vpc_name = "${var.environment}-vpc"
    ec2_name = "${var.environment}-ec2"
    region = var.region
}