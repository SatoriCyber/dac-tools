#!/bin/bash
set -e
# Please fill the following paramaters
ARN_NUMBER="123456789"
AWS_REGION="us-east-1"
VPC_ID="vpc-1ab23c4d5e"
PRIVATE_SUB1_ID="subnet-1a2bc34d"
PRIVATE_SUB2_ID="subnet-1a2bc34d"
PUBLIC_SUB1_ID="subnet-1a2bc34d"
PUBLICS_SUB2_ID="subnet-1a2bc34d"
CLUSTER_NAME='satori-dac'
echo "Creating an AWS DAC with eksctl"
# get eksctl.tar.gz
curl --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" -o "eksctl.tar.gz"
# open the tar.gz
tar zxfv eksctl.tar.gz
# create the cluster yaml
sed "s/AWS_REGION/${AWS_REGION}/g;s/ARN_NUMBER/${ARN_NUMBER}/g;s/CLUSTER_NAME/${CLUSTER_NAME}/g;s/PRIVATE_SUB1_ID/${PRIVATE_SUB1_ID}/g;s/PRIVATE_SUB2_ID/${PRIVATE_SUB2_ID}/g;s/PUBLIC_SUB1_ID/${PUBLIC_SUB1_ID}/g;s/PUBLIC_SUB1_ID/${PUBLIC_SUB2_ID}/g;s/VPC_ID/${VPC_ID}/g;s/EKS_ROLE/${EKS_ROLE}" cluster-template.yaml > ${AWS_REGION}-${CLUSTER_NAME}.yaml
# cluster creation
./eksctl create cluster -f ${AWS_REGION}-${CLUSTER_NAME}.yaml
./eksctl utils associate-iam-oidc-provider --region=${AWS_REGION} --cluster=${CLUSTER_NAME} --approve
# make sure the role exist in AWS IAM
./eksctl create iamidentitymapping --region ${AWS_REGION} --cluster ${CLUSTER_NAME}  --arn arn:aws:iam::${ARN_NUMBER}:role/${EKS_ROLE} --group system:masters --username admin
