### Create EKS cluster ####
#tfsec:ignore:aws-eks-no-public-cluster-access
#tfsec:ignore:aws-eks-no-public-cluster-access-to-cidr
resource "aws_eks_cluster" "eks_cluster" {
  name      = var.cluster_name
  enabled_cluster_log_types = var.log_types
  role_arn  =  aws_iam_role.iam_role_eks_cluster.arn
  version   = "1.29"

  vpc_config {
   endpoint_private_access = true
   endpoint_public_access  = true
   security_group_ids = [aws_security_group.eks_cluster.id]
   #vpc_id             = "${var.vpc_id}"
   subnet_ids         = var.subnet_cluster
    }

  
  encryption_config {
         resources = [ "secrets" ]
         provider {
             key_arn = "arn:aws:kms:ap-southeast-1:464240512619:key/dafc593a-2f1f-4858-9494-e1d1eaf71b08"
         }
     }

  depends_on = [
    aws_cloudwatch_log_group.eks,
    aws_iam_role_policy_attachment.eks_clus_amazoneksclusterpolicy,
    aws_iam_role_policy_attachment.eks_clus_amazoneksservicepolicy,
   ]

tags = {
    Name = "SG-PROD-EKS-INFRA-SPOT-NODE"
    Environment = "Production"
    Project = "sg-eks-prod"
    "Billing Entity" = "Validus Singapore SG"
    Region = "ap-southeast-1"
    "alpha.eksctl.io/cluster-oidc-enabled" = "true"
   }

   tags_all = {
    Name = "SG-PROD-EKS-INFRA-SPOT-NODE"
    Environment = "Production"
    Project = "sg-eks-prod"
    "Billing Entity" = "Validus Singapore SG"
    Region = "ap-southeast-1"
    "alpha.eksctl.io/cluster-oidc-enabled" = "true"
   }

}


### Create security group for AWS EKS. ####
#tfsec:ignore:aws-vpc-no-public-egress-sg
#tfsec:ignore:aws-vpc-no-public-ingress-sg
resource "aws_security_group" "eks_cluster" {
  name        = "prod-eks-cluster-sg"
  description = "Allow TLS inbound traffic from VPC & outbound traffic to internet"
  vpc_id      = var.sg_prod_vpc

  egress {                   # Outbound Rule
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow Outbound traffic from VPC"
  }

  ingress {                  # Inbound Rule
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow Inbound traffic to Internet"
  }

  ingress {                  # Inbound Rule
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow Inbound traffic to Internet"
  }

   ingress {                  # Inbound Rule
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0","172.31.16.0/20","172.31.0.0/20","10.33.112.0/21","10.33.104.0/21"]
    description = "Allow Inbound traffic to Internet"
  }

   ingress {                  # Inbound Rule
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow Inbound traffic to Internet"
  }


   tags_all = {
    Name = "SG-PROD-EKS-INFRA-SPOT-NODE"
    Environment = "Production"
    Project = "sg-eks-prod"
    "Billing Entity" = "Validus Singapore SG"
    Region = "ap-southeast-1"
   }

}

## CW logs for cluster ##

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.cluster_name}/sgcluster"
  retention_in_days = var.log_retention_days
}

