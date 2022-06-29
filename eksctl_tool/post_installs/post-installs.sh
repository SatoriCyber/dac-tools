#!/bin/bash
set -e      

echo -e "Current kubernetes context"
kubectl config current-context
echo $CLUSTER_NAME
echo $AWS_REGION
echo $ACCOUNT_NUMBER

echo "Installing metrics server"
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update 
helm upgrade -i metrics-server -n kube-system --debug metrics-server/metrics-server


echo "Installing node autoscaler"
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm repo update 
pushd ./node-autoscaler
helm upgrade -i -n kube-system cluster-autoscaler --values satori_values.yaml --set 'autoDiscovery.clusterName'=$CLUSTER_NAME --set 'awsRegion'=$AWS_REGION --set rbac.serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=arn:aws:iam::${ACCOUNT_NUMBER}:role/cluster-autoscaler-role-${CLUSTER_NAME} --debug  autoscaler/cluster-autoscaler 
popd 

echo "Installing eks alb controller"
helm repo add eks https://aws.github.io/eks-charts
helm repo update 
helm upgrade -i aws-load-balancer-controller -n kube-system --set clusterName=$CLUSTER_NAME  --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller --debug eks/aws-load-balancer-controller