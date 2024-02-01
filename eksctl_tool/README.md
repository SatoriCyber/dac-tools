# eksctl-bootstrap-cluster

This is a tool aimed at assisting [Satori](https://satoricyber.com) customers when they install their Data Access Controllers (DACs) on AWS EKS environments. If you're not a Satori user, you're still welcome to hang around, or visit our website to learn more about how we [simplify data governance for data in the cloud](https://satoricyber.com).

AWS EKS is a managed Kubernetes solution. The creation has shifted to an open-source tool named EKSCTL, and this repository is using this tool for creating the cluster. We created this repository to help with the cluster's initial creation before deploying our software into the AWS EKS cluster.

The script is intended to run in bash shell.
## Prerequisites
`eksctl`: Please download and install the tool for your platform as described here 
https://eksctl.io/installation/

`kubectl`: While cluster creation runs with the eksctl tool, access to the cluster and the deployment of SatoriCyber software will be done with this tool.
https://kubernetes.io/docs/tasks/tools/install-kubectl/

`Helm v3`: The helm is used to install additional operators for AWS EKS proper functionality:
  1. Metrics server. https://github.com/kubernetes-sigs/metrics-server
  2. AWS EKS cluster autoscaler. https://github.com/kubernetes/autoscaler
  3. AWS EKS load balancer controller.  https://github.com/aws/eks-charts/tree/master/stable/aws-load-balancer-controller  
    
`AWS-CLI`: We recommended to have this tool ready to interact with AWS resources via CLI for future modification and access to the cluster.
https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html

To install the HELM , please follow these instructions: https://helm.sh/docs/intro/install/

## Minimum permissions required for running this tool
  If you use `EXISTING_VPC=true` the minimum IAM policies required to run are [here](./aws_required_policies/iam_eks_policy.json) and [here](./aws_required_policies/limited_ec2_policy.json)
  If you use `EXISTING_VPC=false` you need full ec2 permissions, therefore the minimum IAM policies required to run are [here](./aws_required_policies/iam_eks_policy.json) and [here](./aws_required_policies/full_ec2_policy.json)

## Values and configuration

The creation script will need the following information to be populated by someone with access to the AWS environment before running:
The variables appear in the upper side of the `create-cluster.sh`.

`ACCOUNT_NUMBER`: The AWS account number is used for the cluster creation and permissions distribution.
example - `123456789012`  
`EKS_VERSION`: The EKS version. For example 1.24"  
`CLUSTER_NAME`: The EKS custer name for example "satori-dac-poc"  
`AWS_REGION`: The AWS region, example - `us-east-1`  
  
You must specify 3 availability zones where the cluster node groups will be created and distributed.  
  
  
You must define the `EXISTING_VPC` variable.  
If the value is false, the eksctl will create a dedicated VPC for the cluster. The default VPC CIDR used by eksctl is 192.168.0.0/16. 3 private, 3 public subnets will be created with subnetmask x.x.x.x/19  
You must provide 3 availability zones where the cluster nodes groups will be created and distributed.  
`ZONE_A`: gpr example us-east-1a  
`ZONE_B`: gpr example us-east-1b  
`ZONE_C`: gpr example us-east-1c  
  
The NAT Gateway configuration. For production clusters we strongly recommend setting the value to "HighlyAvailable". therefore the eksctrl will create the separated NAT gateway in every availability zone.  
`NAT_GW_CONFIG` # Possible options: HighlyAvailable (recommended), Disable, Single  
  
When the `EXISTING_VPC` equals `false` all following VPC settings are ignored:  
`VPC_ID`  
`PRIVATE_SUB1_ID`  
`PRIVATE_SUB2_ID`  
`PRIVATE_SUB3_ID`  
`PUBLIC_SUB1_ID`  
`PUBLIC_SUB2_ID`  
`PUBLIC_SUB3_ID`  

If the value of `EXISTING_VPC` is `true`, you must provide existing VPC information.  
  
`VPC_ID`: The existing VPC ID, for example "vpc-0a1b2c4d5e6f1a2b4c"  
  
Three private subnets:  
`PRIVATE_SUB1_ID`  
`PRIVATE_SUB2_ID`  
`PRIVATE_SUB3_ID`  
  
Three public subnets:  
`PUBLIC_SUB1_ID`  
`PUBLIC_SUB2_ID`  
`PUBLIC_SUB3_ID`  
  
We highly recommend providing subnets in three different availability zones.  
If you use an existing VPC, you MUST (!!!) tag subnets allow the EKS to create load balancers correctly, othwerwise load balancers might stuck in  the pending state:

Set tag `kubernetes.io/cluster/<name>` to either shared
Set tag `kubernetes.io/role/internal-elb` to 1 for private subnets
Set tag `kubernetes.io/role/elb` to 1 for public subnets
  
When the `EXISTING_VPC` equals false all following VPC settings are ignored:  
`EXISTING_VPC`  
`ZONE_A`  
`ZONE_B`  
`ZONE_C`  
  
  
## Caveats:  
  
1. Before running the tool with EXISTING_VPC=false (New dedicated VPC will be created), make sure you don't exceed the quota. Special attention should be paid to:  
  "EC2-VPC Elastic IPs per region (default quota is 5)": https://console.aws.amazon.com/servicequotas/home/services/ec2/quotas/L-0263D0A3  
  "VPCs per Region (default quota is 5)": https://console.aws.amazon.com/servicequotas/home/services/vpc/quotas/L-F678F1CE  
  "NAT gateways per Availability Zone (default quota is 5)": https://console.aws.amazon.com/servicequotas/home/services/vpc/quotas/L-FE5A380F  
  "Internet gateways per Region (default quota is 5)":  https://console.aws.amazon.com/servicequotas/home/services/vpc/quotas/L-A4707A72  
  
  If you exceeded your quota or almost exceeded, increase it before running the tool.  
  
2. Before running the tool with EXISTING_VPC=true (Using an existing VPC), make sure the subnets are large enough and have enough free addresses. Special attention should be paid to private subnets where the nodes will be located, since a typical EC2 node reserves about 60 IP addresses, therefore make sure you have a few hundreds of available addresses.  The thumb rule says that you should have about at least 400 available addresses in every subnet to ensure the satori cluster will be functional in case of scaling or other availability zone outage.  
  
