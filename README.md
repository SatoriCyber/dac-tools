# eksctl-bootstrap-cluster

This is a tool aimed at assisting [Satori](https://satoricyber.com) customers when they install their Data Access Controllers (DACs) on AWS EKS environments. If you're not a Satori user, you're still welcome to hang around, or visit our website to learn more about how we [simplify data governance for data in the cloud](https://satoricyber.com).

AWS EKS is a managed Kubernetes solution. The creation has shifted to an open-source tool named EKSCTL, and this repository is using this tool for creating the cluster. We created this repository to help with the cluster's initial creation before deploying our software into the AWS EKS cluster.

The script is indtended to run in bash shell.
## Prerequisites
kubectl: While cluster creation runs with the eksctl tool, access to the cluster and the deployment of SatoriCyber software will be done with this tool.
https://kubernetes.io/docs/tasks/tools/install-kubectl/

AWS-CLI: We recommended to have this tool ready to interact with AWS resources via CLI for future modification and access to the cluster.
https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html

Helm v3: The lem is used to intall additonal operators for AWS EKS proper functionality:
  1. Metrics server. https://github.com/kubernetes-sigs/metrics-server
  2. AWS EKS cluster autoscaler. https://github.com/kubernetes/autoscaler
  3. AWWS EKS load balancer controller.  https://github.com/aws/eks-charts/tree/master/stable/aws-load-balancer-controller
To install the HELM , please folow these instructions: https://helm.sh/docs/intro/install/

## Minimum permissions required for running this tool
   The minimum IAM policies required to run this tools are described here: https://eksctl.io/usage/minimum-iam-policies/

## Values and configuration

The creation script will need the following information to be populated by someone with access to the AWS environment before running:
The variable appear in the upper side of the `create-cluster.sh`.

`ACCOUNT_NUMBER`: The AWS account number is used for the cluster creation and permissions distribution.
example - `123456789012`
`EKS_VERSION`: EKS version. For example 1.21"
`CLUSTER_NAME`: The EKS custer name for example "satori-dac-poc"
`AWS_REGION`: Amazon is running EKS on the EC2 platform, and the availability is listed on the AWS website: https://aws.amazon.com/about-aws/global-infrastructure/regional-product-services/
example - `us-east-1`

You must specify 3 availability zones where the cluster nodes groups will be created and distributed.
`ZONE_A`: gpr example us-east-1a
`ZONE_B`: gpr example us-east-1b
`ZONE_C`: gpr example us-east-1c



`VPC_ID` and `SUBNET_ID`:  A virtual private cloud (VPC) is a virtual network dedicated to your AWS account. It is logically isolated from other virtual networks in the AWS Cloud. You can launch your AWS resources, such as Amazon EC2 instances, into your VPC.
VPC example: `vpc-1a2b3c4d`


