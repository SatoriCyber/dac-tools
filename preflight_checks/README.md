
   
# test_kubernetes.sh  
## This script is intended to verify the following Kubernetes prerequisites for running the satori product:  
The Kubernetes cluster version.   
The existence of default storage class.  
The number of Kubernetes nodes.  
The amount of allocatable memory in each node.  
The number of CPU in each node.  
The amount of available ephemeral storage in each node.  

   
## Prerequisites:  
This script uses the troubleshoot.sh plugin for kubectl (https://troubleshoot.sh/).  
In order to run this tool you need to install the kubectl, the krew packager and the troubleshoot.sh plugins on your local computer.  
   
Install krew:  
   
`(
 set -x; cd "$(mktemp -d)" &&
 OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
 ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
 KREW="krew-${OS}_${ARCH}" &&
 curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
 tar zxvf "${KREW}.tar.gz" &&
 ./"${KREW}" install krew
)`
`export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"`  
   
Install plugins:  
`kubectl krew install preflight`  
`kubectl krew install support-bundle`  
   
## How to run:  
1. Make sure you created the kubeconfig context and you are able to connect to cluster by kubectl.  
2. run ./test_kubernetes.sh  
 
 # test_aws_settings.sh
## This script is intended to verify the following AWS cloud prerequisites for running the satori product:
The Minimum CNI plugin version.  
The existence of 3 node groups spread across 3 available nodes.  
The existence of 3 private subnets in 3 available nodes with appropriate tags required by load balancer controllers.  
The number of free IP addresses in each sunbet.  
The existence of EKS load balancer controller.  
The existence of EKS node auto scaler.  
  
## Prerequisites:  
In order to run this tool you need to install the kubectl and the aws cli on your local computer.  
   
## How to run:  
1. Make sure you created the kubeconfig context and you are able to connect to the cluster by kubectl.  
2. Make sure you have AWS credentials and you are able to connect to AWS by AWS cli.  
3. run ./test_aws_settings.sh  
   