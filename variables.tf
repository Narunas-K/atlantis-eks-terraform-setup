### General variables  ###
variable "region" {
  default = "us-east-1"
}

variable eks_cluster_name {
  default = "test-eks-cluster"
}
variable environment {
  description = "Specifies environment tag, e.g. NTF, QA, PROD, etc"
}

variable ssh_public_key {
}

### Network configuration variables ##
variable vpc_name {
  default = "test-vpc"
}

variable network_address_space {
  default = "10.0.0.0/16"
  description = "VPC network address space"
}

variable private_subnets_addr {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable public_subnets_addr {
  default = ["10.0.4.0/24", "10.0.5.0/24"]
}


### Variables used for Atlantis configuration ###
variable github_user {
  description = "GitHub account name used to setup Atlantis"
}

variable github_token {
  description = "GitHub account token used to setup Atlantis"
}

variable github_secret {
  description = "GitHub account secret used to setup Atlantis"
}

variable github_whitelist {
  description = "Repositories list which Atlantis could access"
}

variable aws_access_key_atlantis {
  description = "AWS account access key used by Atlantis to provision resources on AWS"
}

variable aws_secret_access_key_atlantis {
  description = "AWS account secret access key used by Atlantis to provision resources on AWS"
}