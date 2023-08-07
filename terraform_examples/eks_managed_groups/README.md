# Satori EKS terraform example  

This terraform example is intended to create a basic production-ready EKS cluster which can be used for Satori DAC.  
The Terraform code creates the EKS cluster with three managed node groups in an existing VPC and subnets. The CNI plugin, ELB controller, cluster autoscaller and metrics server are installed as well.  
The example creates the IAM role for DAC for AWS integration feature.  


## Prerequisites  

`AWS-CLI`: We recommended to have this tool ready to interact with AWS resources via CLI for future modification and access to the cluster.  
https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html  

`Existing VPC`: You have to provide exisitng VPC with 3 private subnets. The subnets should be spread accross 3 AZ for high availability. We recomend to have at least 512 free IP addresses in each subnet for proper EKS functionality and fault tolerance. Depending of the type of the Load Balancer (External or Internal) you have to add tags to private or public subnets. See additonal information here https://docs.aws.amazon.com/eks/latest/userguide/network-load-balancing.html  

## Caveats  
The example uses terafrom local state. In real production environemnt we strongly recomend to use a remote terraform state with locking mechanizm. See additonal info here https://developer.hashicorp.com/terraform/language/state/remote


## Values and configuration  

You have to replace few variable in the begging of the main.tf file  

`aws_account`: The AWS account number is used for the cluster creation.
example - `123456789012`  
`cluster_version`: The EKS version. For example `1.27`  
`eks_name`: The EKS custer name for example `satori-dac-poc`  
`region`: The AWS region, example - `us-east-1`  
`vpc_id`: The existing VPC ID, example - `vpc-1a1a1a1a1a1a1a1`  
`private_subnet_ids`: The existing subnet IDs, example - `["subnet-2b2b2b2b2b2b2b", "subnet-3c3c3c3c3c3c3c3c", "subnet-4e4e4e4e4e4e4e4e4e"]` .## Note: Make sure that all three subnets are spread across three availability zones to provide the high availability.  
`bootstrap_extra_args`: You can adjust the amount of reserved CPU and memory for kublet or leave it on suggested values.  

## How to run  
Make sure you are authenticated to the correct AWS account and than run:  
```
terraform init  
terraform apply
```
  