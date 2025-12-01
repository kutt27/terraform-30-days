locals {
    bucket_name = "${var.learner}-bucket-terraform30days-${var.environment}-${var.region}"
    vpc_name = "${var.learner}-vpc-${var.environment}"
    ec2_name = "${var.learner}-ec2-${var.environment}"
    region = var.region
}