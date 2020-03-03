# Atlantis pull request automation app deployment on AWS EKS using Terraform
Terraform project to deploy Atlantis on AWS EKS cluster.

GitHub repo to show Atlantis in action on EKS deployed using this code:
* [Repository](https://github.com/Narunas-K/atlantis-test-repo)
* [Example pull request](https://github.com/Narunas-K/atlantis-test-repo/pull/2)

## Description
This repository contains Terraform code to deploy [Atlantis](https://www.runatlantis.io/) - pull request automation application - on AWS EKS cluster.
Project is based on Terraform [community](https://github.com/terraform-aws-modules) modules such as terraform-aws-eks, terraform-aws-vpc and others.

After applying this Terraform project code you will have:
* 1 VPC with two subnets (one private subnet and one public subnet)
* 1 EKS cluster configured for autoscaling
* Workers autoscaling group and with min=1, max=2 worker nodes
* Workers security groups whcih allow to use AWS bastion host in public subnet
* K8s RBAC configured with to IAM roles: eks-admin and eks-readonly
* Atlantis deployment on EKS cluster and exposed to world using ELB

## Prerequisites to deploy code
To deploy code your workstation need to have:
* Terraform v0.12.21 
* aws-cli (if using MacOS:  `brew install aws-cli` and then `aws configure` to configure AWS credentials)
* jq JSON processor (ff using MacOS: `brew install jq`)
* aws-iam-authenticator (if using MacOs: `brew install aws-iam-authenticator`)

## Deployment procedure
1. Update `terraform.tfvars` file under `NTF/terraform.tfvars` with required variables
2. Run `terraform init`
3. Run `terraform plan -var-file=NTF/terraform.tfvars -out=plan.out`
4. Run `terraform apply plan.out`
5. Watch paint dry..
* **NOTE**: It is possible that after creating an EKS cluster Helm would timeout trying to reach EKS endpoint as the cluster is up but DNS endpoint is still not reachable. In that case you would see simillar error:
```terraform
Error: Post https://<cluster endpoint>.us-east-1.eks.amazonaws.com/api/v1/namespaces/default/services: dial tcp x.x.x.x:443: i/o timeout
	  on modules/kubernetes/k8s-services.tf line 2, in resource "kubernetes_service" "atlantis_endpoint":
	2: resource "kubernetes_service" "atlantis_endpoint" {
.........
Error: Post https://<cluster endpoint>.us-east-1.eks.amazonaws.com/apis/rbac.authorization.k8s.io/v1/clusterrolebindings: dial tcp x.x.x.x:443: i/o timeout
	  on modules/kubernetes/rbac.tf line 44, in resource "kubernetes_cluster_role_binding" "eks-admin-user-role-binding":
  44: resource "kubernetes_cluster_role_binding" "eks-admin-user-role-binding" {
```
To solve this just simply run terraform one more time:
```terraform
terraform plan -var-file=NTF/terraform.tfvars -out=plan.out
terraform apply plan.out
```

Once Terraform finishes its' run in the terminal as outputs you will see generated kubeconfig and Atlantis endpoint DNS name
