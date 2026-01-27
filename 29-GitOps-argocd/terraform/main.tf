data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

# Network setup
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "gitops-vpc"
  cidr = var.vpc_cidr

  azs             = local.azs
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

# Cluster setup
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.30"

  cluster_endpoint_public_access = true
  bootstrap_self_managed_addons  = false

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    initial = {
      instance_types = ["t3.medium"]

      min_size     = 2
      max_size     = 3
      desired_size = 2

      subnet_ids = module.vpc.private_subnets

      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        CloudWatchAgentServerPolicy  = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      }
    }
  }

  enable_irsa                              = true
  enable_cluster_creator_admin_permissions = false
  access_entries = {
    admin = {
      principal_arn = "arn:aws:iam::326864272150:user/terraform-learner"
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
    cluster_admin = {
      principal_arn = aws_iam_role.eks_admin_role.arn
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
  create_kms_key            = false
  cluster_encryption_config = {}

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

# Storage IAM
module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix = "ebs-csi-driver-"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

# LoadBalancer IAM
module "lb_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix = "lb-controller-"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

# Storage Class
resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner = "ebs.csi.aws.com"
  volume_binding_mode = "WaitForFirstConsumer"
  parameters = {
    type   = "gp3"
    fsType = "ext4"
  }
  depends_on = [module.eks]
}

# Cluster Addons
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

# ArgoCD Namespace
resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
  }

  depends_on = [module.eks]
}

# ArgoCD manifests
data "http" "argocd_manifest" {
  url = "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
}

resource "kubectl_manifest" "argocd" {
  for_each = { for doc in split("---", data.http.argocd_manifest.response_body) :
    sha256(doc) => doc if trimspace(doc) != ""
  }

  yaml_body          = each.value
  override_namespace = "argocd"

  depends_on = [kubernetes_namespace_v1.argocd]
}

# Application setup
resource "kubectl_manifest" "app_deployment" {
  yaml_body = file("${path.module}/../manifests/argocd-app.yaml")

  depends_on = [kubectl_manifest.argocd]
}

# Admin permissions
resource "aws_iam_role" "eks_admin_role" {
  name = "EKSClusterAdmin"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::326864272150:root"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_admin_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.eks_admin_role.name
}

# Secret management
resource "aws_secretsmanager_secret" "db_secrets" {
  name                    = "gitops-app-db-secrets"
  description             = "Database credentials for the 3-tier application"
  recovery_window_in_days = 0
  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

resource "aws_secretsmanager_secret_version" "db_secrets_version" {
  secret_id = aws_secretsmanager_secret.db_secrets.id
  secret_string = jsonencode({
    POSTGRES_DB       = "mydb"
    POSTGRES_USER     = "myuser"
    POSTGRES_PASSWORD = "mypassword"
  })
}

# Secrets Access
resource "aws_iam_policy" "secrets_policy" {
  name        = "GitOpsAppSecretsPolicy"
  description = "Allows EKS pods to read database secrets from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Effect   = "Allow"
        Resource = aws_secretsmanager_secret.db_secrets.arn
      }
    ]
  })
}

# Backend permissions
module "backend_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix = "backend-irsa-"

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["3tirewebapp-dev:backend-sa"]
    }
  }

  role_policy_arns = {
    secrets = aws_iam_policy.secrets_policy.arn
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
