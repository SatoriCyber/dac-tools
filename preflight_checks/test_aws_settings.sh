#!/bin/bash
set -e 


CNI_MIN_VERSION=180

WHITE='\033[0;37m'
RED='\033[0;31m'
GREEN='\033[0;32m'

echo "Cluster name:"
read clusterName
echo "AWS Region:"
read awsRegion


echo -e ${WHITE}
errorsReport=""

echo "Checking CNI version..."
kubectl get pods
ver=$(kubectl get ds -n kube-system aws-node -o jsonpath='{$.spec.template.spec.containers[:1].image}' | tr -s '[[:space:]]' '\n' | cut -d ':' -f2 | cut -d '-' -f1 | tr -d -c 0-9)

if [ "$ver" -ge "$CNI_MIN_VERSION" ]; then
    echo -e "${GREEN}The CNI plugin has minimal version number."
    echo -e "${GREEN}Installed version: $ver. Minimum required version: $CNI_MIN_VERSION"
else
    message="${RED}The CNI plugin doesn't meet the minimal version requirements. Installed version: $ver. Minimum required version: $CNI_MIN_VERSION"
    echo -e $message
    errorsReport="$errorsReport \n$message"
fi



echo -e ${WHITE}
echo "Checking AWS load balancer controller..."
result=$(kubectl get pod -A -l app.kubernetes.io/name=aws-load-balancer-controller --field-selector status.phase=Running)
    echo -e "$result"
if [  "$result" != "" ]; then
    echo -e "${GREEN}The AWS load balancer controller has been found  and seems to be working."
else
    message="${RED}The AWS load balancer controller hasn't been found  or isn't working"
    echo -e $message
    errorsReport="$errorsReport \n$message"
fi
result=""

echo -e ${WHITE}
echo "Checking AWS cluster autoscaller .."
result=$(kubectl get pod -A -l app.kubernetes.io/name=aws-cluster-autoscaler --field-selector status.phase=Running)
echo -e "$result"
if [  "$result" != "" ]; then
    echo -e "${GREEN}The AWS cluster autoscaller has been found  and seems to be working."
else
    message="${RED}The AWS cluster autoscaller hasn't been found  or isn't working"
    echo -e $message
    errorsReport="$errorsReport \n$message"
fi
result=""

echo -e ${WHITE}
echo "Checking node groups..."
nodeGroups=$(aws eks list-nodegroups --cluster-name $clusterName --region $awsRegion  --output text  --query 'nodegroups[*]')
echo -e "Found these node groups: ${nodeGroups}"
nodeGroups=(`echo $nodeGroups | tr ' ' ' '`)
if [  ${#nodeGroups[@]} -ge 3 ]; then
    echo -e "${GREEN}The node groups number meets the requirements. Found ${#nodeGroups[@]} node groups"
else
    message="${RED}The node groups number doesn't meet the requirements. Found only ${#nodeGroups[@]} node groups. Required 3 node groups spread accros 3 availability zones"
    echo -e $message
    errorsReport="$errorsReport \n$message"
    

fi


echo -e ${WHITE}
echo -e "Checking node groups subnets..."
# Declare a string array for availability zones
azs=("us-east-1c")
for i in "${nodeGroups[@]}" 
do
    echo -e "${WHITE}Checking subnets for node group $i..."
    subnet=$(aws eks describe-nodegroup --nodegroup-name $i --cluster-name $clusterName --region $awsRegion --output text --query 'nodegroup.subnets')
    echo -e "The node group $i has  the subnet $subnet"
    echo -e "Checking subnet $subnet"
    az=$(aws ec2 describe-subnets --subnet-ids $subnet --region $awsRegion --output text --query 'Subnets[*].AvailabilityZone')
    freeAddresses=$(aws ec2 describe-subnets --subnet-ids $subnet --region $awsRegion --output text --query 'Subnets[*].AvailableIpAddressCount')
    if [  "$freeAddresses" -ge 300 ]; then
        echo -e "${GREEN}The subnet $subnet has $freeAddresses free IP address. It's good enough"
    else
        message="${RED}The subnet $subnet has only $freeAddresses free IP address. For redundancy and fault tolerance we recommend to keep at least 300 free IP addresses"
        echo -e $message
        errorsReport="$errorsReport \n$message"
    fi

    echo -e "${WHITE}The subnet $subnet is located in availability zone $az"
    azs+=($az)
    echo -e "${WHITE}Checking tags for subnet $subnet..."
    internlElbTag=$(aws ec2 describe-subnets --subnet-ids $subnet --region $awsRegion --output text  --query 'Subnets[*].Tags[?Key==`kubernetes.io/role/internal-elb`].Value[]')
    if [  "$internlElbTag" -eq 1 ]; then
        echo -e "${GREEN}The 'kubernetes.io/role/internal-elb' tag with value 1 has been found on subnet $subnet"
    else
        message="${RED}The 'kubernetes.io/role/internal-elb' tag with value 1 hasn't been found on subnet $subnet"
        echo -e $message
        errorsReport="$errorsReport \n$message"
    fi
    clusterTag=$(aws ec2 describe-subnets --subnet-ids $subnet --region $awsRegion --output text  --query 'Subnets[*].Tags[?Key==`kubernetes.io/cluster/'$clusterName'`].Value[]')

    if [  "$clusterTag" == "owned" ] || [ "$clusterTag" == "shared" ]; then
        echo -e "${GREEN}The 'kubernetes.io/cluster/${clusterName}' tag with value 'shared' or 'owned' has been found on subnet $subnet"
    else
        message="${RED}The 'kubernetes.io/cluster/${clusterName}' tag with value 'shared' or 'owned' hasn't been found on subnet $subnet"
        echo -e $message
        errorsReport="$errorsReport \n$message"
    fi
done

uniqAzs=($(printf "%s\n" "${azs[@]}" | sort -u | tr '\n' ' '))


if [ ${#uniqAzs[@]} -ge 3 ]; then
  echo -e "${GREEN}The cluster is spread across ${#uniqAzs[@]} availability zones. It's good enough"
else
  message="${RED}The cluster has only ${#uniqAzs[@]} availability zones. We strongly recommend to spread the cluster across at least 3 availability zones"
  echo -e $message
  errorsReport="$errorsReport \n$message"
fi

echo -e ${WHITE}
echo "Checking node image..."
image=$(kubectl get node -o  jsonpath='{$.items[0].metadata.labels.eks\.amazonaws\.com/nodegroup-image}')
if [  "$image" != "" ]; then
   echo -e "The image ID is: $image"
   imageOwner=$(aws ec2  describe-images --image-ids $image --region $awsRegion --query 'Images[0].ImageOwnerAlias' | tr -d '"')
   imageLocation=$(aws ec2  describe-images --image-ids $image --region $awsRegion --query 'Images[0].ImageLocation' | tr -d '"')
   echo -e "The image owner is: $imageOwner"
   echo -e "The image location is: $imageLocation" 
fi
if [[  "$imageOwner" == "amazon" ]] && [[ "$imageLocation" =~ .*"amazon-eks-node".* ]]; then
    echo -e "${GREEN}The nodes are using an official amazon kubernetes image."
else
    message="${RED}The nodes are using NON official amazon kubernetes image. This is the informational message.Custom images might work stable if built properly."
    echo -e $message
    errorsReport="$errorsReport \n$message"
fi





echo -e "${WHITE}\n\n\n\n\n\nFinal report:"
if [ "$errorsReport" != "" ]; then
  echo -e "${RED}Following errors have been found:\n$errorsReport\n"
else
  echo -e "${GREEN}No errors have been found. Everything is ok."
fi
