#!/bin/bash
set -e
# Please fill the following paramaters
ACCOUNT_NUMBER="105246067165"
EKS_VERSION="1.21"
CLUSTER_NAME="satori-dac-poc2"


AWS_REGION="us-east-1"
ZONE_A="us-east-1a"
ZONE_B="us-east-1b"
ZONE_C="us-east-1c"
NAT_GW_CONFIG="Single"  # other options: HighlyAvailable (recommended), Disable, Single 

EXISTING_VPC=true
VPC_ID="vpc-04ce41b172522770e"
PRIVATE_SUB1_ID="subnet-0409cf42d68b62649"
PRIVATE_SUB2_ID="subnet-097b9d90f3f0a182e"
PRIVATE_SUB3_ID="subnet-0a2a93569abc65f06"
PUBLIC_SUB1_ID="subnet-0a2a93569abc65f06"
PUBLIC_SUB2_ID="subnet-013f8a0e07c6f9db0"
PUBLIC_SUB3_ID="subnet-02380d22f1b2fd1a9"


echo "Creating an AWS DAC with eksctl"
# get eksctl.tar.gz
curl --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" -o "eksctl.tar.gz"
# open the tar.gz
tar zxfv eksctl.tar.gz





# create the cluster yaml
sed "s/NAT_GW_CONFIG/${NAT_GW_CONFIG}/g;s/EKS_VERSION/${EKS_VERSION}/g;s/AWS_REGION/${AWS_REGION}/g;s/ACCOUNT_NUMBER/${ACCOUNT_NUMBER}/g;s/CLUSTER_NAME/${CLUSTER_NAME}/g;s/PRIVATE_SUB1_ID/${PRIVATE_SUB1_ID}/g;s/PRIVATE_SUB2_ID/${PRIVATE_SUB2_ID}/g;s/PRIVATE_SUB3_ID/${PRIVATE_SUB3_ID}/g;s/PUBLIC_SUB1_ID/${PUBLIC_SUB1_ID}/g;s/PUBLIC_SUB2_ID/${PUBLIC_SUB2_ID}/g;s/PUBLIC_SUB3_ID/${PUBLIC_SUB3_ID}/g;s/VPC_ID/${VPC_ID}/g;s/EKS_ROLE/${EKS_ROLE}/g" cluster-template.yaml > ${AWS_REGION}-${CLUSTER_NAME}.yaml
if [ "$EXISTING_VPC" == true ] ; then
   sed '/availabilityZones.*,.*/d' ${AWS_REGION}-${CLUSTER_NAME}.yaml > tmpfile ; mv tmpfile ${AWS_REGION}-${CLUSTER_NAME}.yaml
   sed  "s/# # # # # #//g" ${AWS_REGION}-${CLUSTER_NAME}.yaml > tmpfile ; mv tmpfile ${AWS_REGION}-${CLUSTER_NAME}.yaml
fi
sed "s/ZONE_A/${ZONE_A}/g;s/ZONE_B/${ZONE_B}/g;s/ZONE_C/${ZONE_C}/g" ${AWS_REGION}-${CLUSTER_NAME}.yaml > tmpfile ; mv tmpfile ${AWS_REGION}-${CLUSTER_NAME}.yaml



echo -e "\n\n\n\nPlease validate the final cluster config file named ${AWS_REGION}-${CLUSTER_NAME}.yaml. \n\n"
read -p "If everything is ok type yes to start creating the cluster: " CONT
echo
if [ "$CONT" = "yes" ]; then
   # cluster creation
  # ./eksctl create cluster -f ${AWS_REGION}-${CLUSTER_NAME}.yaml
   ./eksctl utils write-kubeconfig --cluster=${CLUSTER_NAME} --region=${AWS_REGION}
   export CLUSTER_NAME=$CLUSTER_NAME
   export AWS_REGION=$AWS_REGION
   export ACCOUNT_NUMBER=$ACCOUNT_NUMBER
   pushd ./post_installs
   chmod +x ./post-installs.sh
   ./post-installs.sh
else
    echo "exiting..."
fi 




