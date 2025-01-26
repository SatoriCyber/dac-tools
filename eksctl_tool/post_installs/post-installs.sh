#!/bin/bash
set -e      

echo -e "Current kubernetes context"
kubectl config current-context
echo $CLUSTER_NAME
echo $AWS_REGION
echo $ACCOUNT_NUMBER


echo "Installing node autoscaler"

if [[ "$AWS_REGION" == "us-gov"* ]]; then
   echo "This is gov cloud"
   ARN_STRING="aws-us-gov"
else
   echo "This is non gov cloud"
   ARN_STRING="aws"
fi



helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm repo update 
pushd ./node-autoscaler
helm upgrade -i -n kube-system cluster-autoscaler --values satori_values.yaml --set 'autoDiscovery.clusterName'=$CLUSTER_NAME --set 'awsRegion'=$AWS_REGION --set rbac.serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=arn:${ARN_STRING}:iam::${ACCOUNT_NUMBER}:role/cluster-autoscaler-role-${CLUSTER_NAME} --debug  autoscaler/cluster-autoscaler 
popd 

echo "Installing eks alb controller"
helm repo add eks https://aws.github.io/eks-charts
helm repo update 
helm upgrade -i aws-load-balancer-controller -n kube-system --set clusterName=$CLUSTER_NAME  --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller --debug eks/aws-load-balancer-controller