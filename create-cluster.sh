#!/bin/bash
set -e

# Please fill the following paramaters
ACCOUNT_NUMBER="105246067165"
EKS_VERSION="1.21"
CLUSTER_NAME="satori-dac-poc1"
AWS_REGION="us-east-1"

EXISTING_VPC=false

ZONE_A="us-east-1a"
ZONE_B="us-east-1b"
ZONE_C="us-east-1c"
NAT_GW_CONFIG="HighlyAvailable"  # other options: HighlyAvailable (recommended), Disable, Single 


VPC_ID="vpc-0599b80d7b45215c3"
PRIVATE_SUB1_ID="subnet-03182bb32e36dd69c"
PRIVATE_SUB2_ID="subnet-0b5e55789fcdf5922"
PRIVATE_SUB3_ID="subnet-0126c81c0891709c3"
PUBLIC_SUB1_ID="subnet-0744841e4667d619d"
PUBLIC_SUB2_ID="subnet-0f94ea609cde1c230"
PUBLIC_SUB3_ID="subnet-05f4f9562f841a57d"













if ! command -v aws &> /dev/null
then
    echo "The aws cli is required by isn't isntalled"
    echo "Please refer to about aws cli https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html"
    exit 1
fi

if ! command -v kubectl &> /dev/null
then
    echo "The kubectl is required by isn't isntalled"
    echo "Please refer to about kubectl https://kubernetes.io/docs/tasks/tools/install-kubectl/"
    exit 1
fi
if ! command -v helm &> /dev/null
then
    echo "The helm is required by isn't isntalled"
    echo "Please refer to about helm https://helm.sh/docs/intro/install/"
    exit 1
fi

connected_account=$(aws sts get-caller-identity --query Account | tr -d '"')

if [ "$ACCOUNT_NUMBER" != "$connected_account" ] ; then
   echo "Your cuurent credentials are diifrent from configured AWS account number. For your protection the script will not run. Please, check your current AWS credentials"
   echo -e "Connected account: $connected_account"
   echo -e "Configured account: $ACCOUNT_NUMBER"
   exit 1
fi

echo "Creating an AWS DAC with eksctl"
# get eksctl.tar.gz
curl --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" -o "eksctl.tar.gz"
# open the tar.gz
tar zxfv eksctl.tar.gz





# create the cluster yaml
sed "s/NAT_GW_CONFIG/${NAT_GW_CONFIG}/g;s/EKS_VERSION/${EKS_VERSION}/g;s/AWS_REGION/${AWS_REGION}/g;s/ACCOUNT_NUMBER/${ACCOUNT_NUMBER}/g;s/CLUSTER_NAME/${CLUSTER_NAME}/g;s/PRIVATE_SUB1_ID/${PRIVATE_SUB1_ID}/g;s/PRIVATE_SUB2_ID/${PRIVATE_SUB2_ID}/g;s/PRIVATE_SUB3_ID/${PRIVATE_SUB3_ID}/g;s/PUBLIC_SUB1_ID/${PUBLIC_SUB1_ID}/g;s/PUBLIC_SUB2_ID/${PUBLIC_SUB2_ID}/g;s/PUBLIC_SUB3_ID/${PUBLIC_SUB3_ID}/g;s/VPC_ID/${VPC_ID}/g;s/EKS_ROLE/${EKS_ROLE}/g" cluster-template.yaml > ${AWS_REGION}-${CLUSTER_NAME}.yaml
if [ "$EXISTING_VPC" == true ] ; then
   sed '/availabilityZones/d' ${AWS_REGION}-${CLUSTER_NAME}.yaml > tmpfile ; mv tmpfile ${AWS_REGION}-${CLUSTER_NAME}.yaml
   sed  "s/# # # # # #//g" ${AWS_REGION}-${CLUSTER_NAME}.yaml > tmpfile ; mv tmpfile ${AWS_REGION}-${CLUSTER_NAME}.yaml
else
   sed '/subnet/d' ${AWS_REGION}-${CLUSTER_NAME}.yaml > tmpfile ; mv tmpfile ${AWS_REGION}-${CLUSTER_NAME}.yaml
fi
sed "s/ZONE_A/${ZONE_A}/g;s/ZONE_B/${ZONE_B}/g;s/ZONE_C/${ZONE_C}/g" ${AWS_REGION}-${CLUSTER_NAME}.yaml > tmpfile ; mv tmpfile ${AWS_REGION}-${CLUSTER_NAME}.yaml



echo -e "\n\n\n\nPlease validate the final cluster config file named ${AWS_REGION}-${CLUSTER_NAME}.yaml. \n\n"
read -p "If everything is ok type 'yes' to start creating the cluster: " CONT
echo
if [ "$CONT" = "yes" ]; then
   # cluster creation
   ./eksctl create cluster -f ${AWS_REGION}-${CLUSTER_NAME}.yaml
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




