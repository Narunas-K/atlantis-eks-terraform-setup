##################################################################################
# LOCAL VARIABLES
##################################################################################
locals {
//  Roles list to be added to K8s AWS config map
  role-map-list = [
    {
      rolearn = module.sg-iam.eks_readonly_role_arn
      username = "eks-readonly"
      groups   = ["eks-readonly-user-role"]
    },
    {
      rolearn  = module.sg-iam.eks_admin_role_arn
      username = "eks-admin"
      groups   = ["cluster-admin"]
    },
  ]
//  local variables used to setup AWS EKS cluster autoscaler deployment
  k8s_service_account_namespace = "kube-system"
  k8s_service_account_name      = "cluster-autoscaler-aws-cluster-autoscaler"
}

##################################################################################
# RESOURCES
##################################################################################
resource "aws_key_pair" "eks_workers_key" {
  key_name   = "eks-workers-key"
  public_key = var.ssh_public_key
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.6.0"
  name                 = var.vpc_name
  cidr                 = var.network_address_space
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = var.private_subnets_addr
  public_subnets       = var.public_subnets_addr
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

//security groups and IAM roles/policies setup module
module "sg-iam" {
  source = "./modules/sg-iam"
  aws_acccount_id = data.aws_caller_identity.current.account_id
  vpc_id = module.vpc.vpc_id
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  eks_cluster_id = var.eks_cluster_name
  k8s_service_account_name = local.k8s_service_account_name
  k8s_service_account_namespace = local.k8s_service_account_namespace
}

//Module which handles K8s configuration and Helm charts installation
module "kubernetes" {
  source = "./modules/kubernetes"
  github_secret = var.github_secret
  github_token = var.github_token
  github_user = var.github_user
  github_whitelist = var.github_whitelist
  aws_access_key = var.aws_access_key_atlantis
  aws_secret_access_key = var.aws_secret_access_key_atlantis
  aws_account_id = data.aws_caller_identity.current.account_id
  cluster_name = var.eks_cluster_name
  aws_region = var.region
}

//Module to setup AWS EKS cluster
module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  cluster_name = var.eks_cluster_name
  vpc_id = module.vpc.vpc_id
  subnets      = module.vpc.private_subnets
  enable_irsa  = true

  tags = {
    Environment = var.environment
  }

    worker_groups = [
    {
      name                 = "worker-group-1"
      instance_type        = "t2.small"
      asg_desired_capacity = 1
      asg_min_size                  = 1
      asg_max_size                  = 2
      key_name = "eks-workers-key"
      additional_security_group_ids = [module.sg-iam.worker_management_sg]

//Tags needed to enable EKS cluster nodes autoscaling
      tags = [
        {
          "key"                 = "k8s.io/cluster-autoscaler/enabled"
          "propagate_at_launch" = "false"
          "value"               = "true"
        },
        {
          "key"                 = "k8s.io/cluster-autoscaler/${var.eks_cluster_name}"
          "propagate_at_launch" = "false"
          "value"               = "true"
        }
      ]
    }
  ]
  map_roles                            = local.role-map-list
}
