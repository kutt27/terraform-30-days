# Kubernetes Addons Module Variables

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "cluster_identity_oidc_issuer" {
  description = "The OIDC Identity issuer for the cluster"
  type        = string
}

variable "cluster_identity_oidc_issuer_arn" {
  description = "The OIDC Identity issuer ARN for the cluster"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

# Helm Chart Versions
variable "metrics_server_version" {
  description = "Metrics Server helm chart version"
  type        = string
}

variable "aws_lb_controller_version" {
  description = "AWS Load Balancer Controller helm chart version"
  type        = string
}

variable "prometheus_version" {
  description = "Prometheus helm chart version"
  type        = string
}

variable "argocd_version" {
  description = "ArgoCD helm chart version"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
